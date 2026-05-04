# helpers.R — Reusable analysis functions for the battery drain factorial experiment
# Base R only. Source this file: source("R/helpers.R")


# half_normal_plot: Half-normal plot of effects with labeling
# model: a fitted lm() object from a 2^k factorial (or named numeric vector of effects, with `effects =`)
# n_label: number of largest effects to label (default 5)
# drop_terms: pattern to exclude from the effects (e.g. "DayF" drops Day block contrasts)
half_normal_plot = function(model, n_label = 5, drop_terms = NULL,
                            main = "Half-Normal Plot of Effects",
                            effects = NULL) {
  if (is.null(effects)) {
    coefs = coef(model)
    effects = coefs[-1]
  }
  if (!is.null(drop_terms)) {
    effects = effects[!grepl(drop_terms, names(effects))]
  }
  abs_effects = abs(effects)
  n = length(abs_effects)

  half_normal_q = qnorm(0.5 + (1:n) / (2 * n + 1))
  sorted_idx = order(abs_effects)
  sorted_effects = abs_effects[sorted_idx]
  sorted_names = names(abs_effects)[sorted_idx]

  plot(half_normal_q, sorted_effects,
       xlab = "Half-Normal Quantiles",
       ylab = "|Effect|",
       main = main,
       pch = 16, col = "steelblue",
       xlim = c(-0.05, max(half_normal_q) * 1.15))

  n_fit = max(2, floor(n / 2))
  fit = lm(sorted_effects[1:n_fit] ~ half_normal_q[1:n_fit])
  abline(fit, lty = 2, col = "gray50")

  # Label only the top n_label effects.
  # Stagger labels left/right when adjacent points have close |effect| values
  # to avoid label overlap.
  k = min(n_label, n)
  big_idx = (n - k + 1):n
  pos_vec = rep(2, length(big_idx)) # default: label to the left
  if (length(big_idx) >= 2) {
    diffs = diff(sorted_effects[big_idx])
    span = max(sorted_effects[big_idx]) - min(sorted_effects[big_idx])
    threshold = max(span * 0.07, 0.05)
    for (j in 2:length(big_idx)) {
      if (diffs[j - 1] < threshold) {
        # Adjacent labels are close in y; flip this one to the right
        pos_vec[j] = if (pos_vec[j - 1] == 2) 4 else 2
      }
    }
  }
  text(half_normal_q[big_idx], sorted_effects[big_idx],
       labels = sorted_names[big_idx],
       pos = pos_vec, cex = 0.78, col = "red", offset = 0.4)

  invisible(data.frame(effect = sorted_names, abs_value = sorted_effects,
                       quantile = half_normal_q))
}


# calc_effects: Extract and display all effects from a 2^k model
# model: a fitted lm() object
# Returns a data frame of effects sorted by absolute value
calc_effects = function(model) {
  coefs = coef(model)
  effects = coefs[-1] # drop intercept
  # In a 2^k with -1/+1 coding, effects = 2 * coefficients
  # But if factors are already coded -1/+1, the coefficient IS half the effect
  # So the effect = 2 * coefficient
  effect_vals = 2 * effects
  result = data.frame(
    Effect = names(effect_vals),
    Estimate = as.numeric(effect_vals),
    AbsEstimate = abs(as.numeric(effect_vals))
  )
  result = result[order(-result$AbsEstimate), ]
  rownames(result) = NULL
  cat("Estimated Effects (sorted by |effect|):\n")
  print(result[, c("Effect", "Estimate")], row.names = FALSE)
  invisible(result)
}


# interaction_panel: Generate pairwise interaction plots
# data: data frame with factors and response
# response: name of the response column (string)
# factors: character vector of factor column names
interaction_panel = function(data, response, factors) {
  pairs = combn(factors, 2)
  n_pairs = ncol(pairs)
  n_col = min(3, n_pairs)
  n_row = ceiling(n_pairs / n_col)
  par(mfrow = c(n_row, n_col))

  colors = c("steelblue", "tomato")

  for (i in 1:n_pairs) {
    f1 = pairs[1, i]
    f2 = pairs[2, i]
    # Compute cell means
    means = tapply(data[[response]], list(data[[f1]], data[[f2]]), mean)
    levels_f2 = colnames(means)

    # Set up plot
    x_vals = as.numeric(rownames(means))
    if (any(is.na(x_vals))) x_vals = 1:nrow(means)

    y_range = range(means, na.rm = TRUE)
    y_pad = diff(y_range) * 0.1
    plot(x_vals, means[, 1], type = "b", pch = 16, col = colors[1],
         xlab = f1, ylab = paste("Mean", response),
         main = paste(f1, "x", f2, "Interaction"),
         ylim = c(y_range[1] - y_pad, y_range[2] + y_pad),
         xaxt = "n", lwd = 2)
    axis(1, at = x_vals, labels = rownames(means))

    for (j in 2:ncol(means)) {
      lines(x_vals, means[, j], type = "b", pch = 17, col = colors[min(j, length(colors))], lwd = 2)
    }

    legend("topright",
           legend = paste(f2, "=", levels_f2),
           col = colors[1:length(levels_f2)],
           pch = c(16, 17), lwd = 2, cex = 0.8, bty = "n")
  }

  par(mfrow = c(1, 1))
}


# diagnostic_panel: 2x2 residual diagnostic plots
# model: a fitted lm() or aov() object
diagnostic_panel = function(model, main_prefix = "") {
  par(mfrow = c(2, 2))

  # 1. Residuals vs Fitted
  plot(fitted(model), residuals(model),
       xlab = "Fitted Values", ylab = "Residuals",
       main = paste0(main_prefix, "Residuals vs Fitted"),
       pch = 16, col = "steelblue")
  abline(h = 0, lty = 2, col = "red")

  # 2. Normal Q-Q Plot
  qqnorm(residuals(model), pch = 16, col = "steelblue",
         main = paste0(main_prefix, "Normal Q-Q Plot"))
  qqline(residuals(model), col = "red", lwd = 2)

  # 3. Scale-Location
  std_resid = residuals(model) / summary(model)$sigma
  plot(fitted(model), sqrt(abs(std_resid)),
       xlab = "Fitted Values", ylab = expression(sqrt("|Standardized Residuals|")),
       main = paste0(main_prefix, "Scale-Location"),
       pch = 16, col = "steelblue")
  lo = lowess(fitted(model), sqrt(abs(std_resid)))
  lines(lo, col = "red", lwd = 2)

  # 4. Residuals vs Run Order
  plot(1:length(residuals(model)), residuals(model),
       xlab = "Run Order", ylab = "Residuals",
       main = paste0(main_prefix, "Residuals vs Run Order"),
       pch = 16, col = "steelblue")
  abline(h = 0, lty = 2, col = "red")

  par(mfrow = c(1, 1))
}


# lenth_test: Lenth's method for identifying significant effects
# effects: named numeric vector of effect estimates
# Returns a data frame with PSE, ME, SME, and significance flags
lenth_test = function(effects, alpha = 0.05) {
  abs_effects = abs(effects)

  # Step 1: Initial estimate s0 = 1.5 * median(|effects|)
  s0 = 1.5 * median(abs_effects)

  # Step 2: PSE = 1.5 * median of |effects| that are <= 2.5 * s0
  trimmed = abs_effects[abs_effects <= 2.5 * s0]
  PSE = 1.5 * median(trimmed)

  # Step 3: Compute margin of error and simultaneous margin of error
  m = length(effects)
  # Degrees of freedom for Lenth's method
  df = m / 3

  ME = qt(1 - alpha / 2, df) * PSE
  # Simultaneous ME uses Bonferroni-like correction
  SME = qt(1 - alpha / (2 * m), df) * PSE

  result = data.frame(
    Effect = names(effects),
    Estimate = as.numeric(effects),
    AbsEstimate = abs(as.numeric(effects)),
    Significant_ME = abs(as.numeric(effects)) > ME,
    Significant_SME = abs(as.numeric(effects)) > SME
  )
  result = result[order(-result$AbsEstimate), ]
  rownames(result) = NULL

  cat(sprintf("Pseudo Standard Error (PSE): %.4f\n", PSE))
  cat(sprintf("Margin of Error (ME, alpha=%.2f): %.4f\n", alpha, ME))
  cat(sprintf("Simultaneous ME (SME): %.4f\n", SME))
  cat("\n")
  print(result, row.names = FALSE)

  invisible(list(PSE = PSE, ME = ME, SME = SME, results = result))
}
