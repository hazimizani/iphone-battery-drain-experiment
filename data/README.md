# Battery Drain Experiment — Data Dictionary

## File: `battery_drain.csv`

| Column | Type | Description |
|--------|------|-------------|
| Run | integer | Global run order (1–48) |
| Day | integer | Day of experiment (1, 2, or 3) — blocking factor |
| A_Brightness | integer | Screen brightness: -1 = 25%, +1 = 100% |
| B_WiFi | integer | WiFi status: -1 = Off (Airplane), +1 = On |
| C_Workload | integer | App workload: -1 = Idle, +1 = Active (video loop) |
| D_LowPower | integer | Low Power Mode: -1 = On, +1 = Off |
| BatteryStart | numeric | Battery % at start of 15-min interval (0.1% precision) |
| BatteryEnd | numeric | Battery % at end of 15-min interval (0.1% precision) |
| Drain | numeric | Battery drop = BatteryStart - BatteryEnd (0.1% precision) |

Battery percentages were recorded with 0.1% resolution from iOS battery statistics rather than the integer home-screen indicator.

## Design

- 2^4 full factorial (16 treatment combinations)
- 3 replicates per combination (48 total runs)
- One full replicate per Day (Day acts as a complete block)
- Runs randomized within each Day
- Day used as blocking factor in the analysis

## Factor Details

| Factor | Low (-1) | High (+1) |
|--------|----------|-----------|
| A: Screen Brightness | 25% | 100% |
| B: WiFi | Off (Airplane mode) | On (connected) |
| C: App Workload | Idle (home screen) | Active (local video loop) |
| D: Low Power Mode | On | Off |
