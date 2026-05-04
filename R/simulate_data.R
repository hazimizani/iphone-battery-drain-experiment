# simulate_data.R
# Generates Project/data/battery_drain.csv for the 2^4 battery drain experiment
# Run from the Project/ directory: Rscript R/simulate_data.R

set.seed(42424)

# 2^4 design matrix
combos = expand.grid(
  D_LowPower   = c(-1, 1),
  C_Workload   = c(-1, 1),
  B_WiFi       = c(-1, 1),
  A_Brightness = c(-1, 1)
)
combos = combos[, c("A_Brightness", "B_WiFi", "C_Workload", "D_LowPower")]
n_combos = nrow(combos)
n_days = 3

# Effect structure (in coded units: -1 / +1)
intercept = 4.0
beta_A  = 0.70   # main effect coefficient (effect = 2*beta = 1.40)
beta_B  = 0.20
beta_C  = 1.30
beta_D  = 0.55
beta_AC = 0.25
beta_CD = 0.30
beta_BD = 0.05
beta_AB = 0.03
beta_AD = 0.02
beta_BC = 0.04
beta_ABC = 0.02
beta_ABD = 0.01
beta_ACD = 0.03
beta_BCD = 0.01
beta_ABCD = 0.02

# Day effects (sum to zero so they don't shift the grand mean)
day_effect = c(`1` = -0.05, `2` = 0.10, `3` = -0.05)

# Heteroscedastic noise: variability higher when workload is active
sigma_idle   = 0.30
sigma_active = 0.50

# Build design with one full replicate per day
all_runs = NULL
for (d in 1:n_days) {
  day_combos = combos
  day_combos$Day = d
  day_combos = day_combos[sample(n_combos), ]
  all_runs = rbind(all_runs, day_combos)
}
all_runs$Run = 1:nrow(all_runs)

# True conditional mean
A = all_runs$A_Brightness
B = all_runs$B_WiFi
C = all_runs$C_Workload
D = all_runs$D_LowPower
mu = intercept +
  beta_A*A + beta_B*B + beta_C*C + beta_D*D +
  beta_AB*A*B + beta_AC*A*C + beta_AD*A*D +
  beta_BC*B*C + beta_BD*B*D + beta_CD*C*D +
  beta_ABC*A*B*C + beta_ABD*A*B*D + beta_ACD*A*C*D + beta_BCD*B*C*D +
  beta_ABCD*A*B*C*D +
  day_effect[as.character(all_runs$Day)]

# Noise (depends on workload)
sigma_vec = ifelse(all_runs$C_Workload == 1, sigma_active, sigma_idle)
all_runs$Drain = round(mu + rnorm(nrow(all_runs), 0, sigma_vec), 1)

# Battery start at ~93 +/- 2 (charged to ~95% before each run, with small variation)
start_raw = 93 + rnorm(nrow(all_runs), 0, 1.2)
all_runs$BatteryStart = pmin(96.5, pmax(89.5, round(start_raw, 1)))
all_runs$BatteryEnd   = round(all_runs$BatteryStart - all_runs$Drain, 1)

# Final column order
out = all_runs[, c("Run", "Day", "A_Brightness", "B_WiFi",
                   "C_Workload", "D_LowPower",
                   "BatteryStart", "BatteryEnd", "Drain")]

write.csv(out, "data/battery_drain.csv", row.names = FALSE)

# Sanity report
cat("Generated", nrow(out), "runs\n")
cat("Drain range:", range(out$Drain), "\n")
cat("Drain mean:", round(mean(out$Drain), 2), "\n")
cat("Per-day drain mean:\n")
print(round(tapply(out$Drain, out$Day, mean), 3))
cat("\nCell variance ratio (active vs idle workload):\n")
v_active = mean(tapply(out$Drain[out$C_Workload == 1],
                       paste(out$A_Brightness, out$B_WiFi, out$D_LowPower)[out$C_Workload == 1],
                       var))
v_idle = mean(tapply(out$Drain[out$C_Workload == -1],
                     paste(out$A_Brightness, out$B_WiFi, out$D_LowPower)[out$C_Workload == -1],
                     var))
cat(sprintf("  active mean s^2 = %.3f, idle mean s^2 = %.3f, ratio = %.2f\n",
            v_active, v_idle, v_active/v_idle))
