---
name: data-processing
description: Data processing with pandas 2.x, numpy 2.x, polars, Dask. ETL pipelines, data cleaning, visualization, performance optimization for large datasets.
---

# Data Processing Skill

## When to Activate
- Working with pandas DataFrames, numpy arrays
- ETL/data pipeline development
- Data cleaning, transformation, aggregation
- Large dataset processing and optimization
- Data visualization with matplotlib/plotly

## Library Selection

| Library | Best For | Speed |
|---------|----------|-------|
| **pandas 2.x** | General data manipulation, small-medium datasets (<1GB) | Good |
| **polars** | Large datasets, fast aggregation, lazy evaluation | Fastest |
| **numpy 2.x** | Numerical computation, arrays, linear algebra | Fast |
| **Dask** | Datasets larger than RAM, parallel processing | Scalable |
| **pyarrow** | Columnar format, interop between libraries | Fast I/O |

**Default: pandas** for most tasks. Switch to **polars** for performance-critical or >500MB datasets.

## pandas Core Patterns

### Data Loading
```python
import pandas as pd

# CSV with type optimization
df = pd.read_csv("data.csv", dtype={
    "id": "int32",
    "name": "string",        # Use StringDtype, not object
    "amount": "float32",
    "date": "string",
}, parse_dates=["date"])

# Chunked reading for large files
chunks = pd.read_csv("huge.csv", chunksize=100_000)
results = []
for chunk in chunks:
    processed = process(chunk)
    results.append(processed)
df = pd.concat(results, ignore_index=True)

# Parquet (much faster than CSV)
df = pd.read_parquet("data.parquet")
df.to_parquet("output.parquet", index=False)
```

### Memory Optimization
```python
def optimize_dtypes(df: pd.DataFrame) -> pd.DataFrame:
    """Downcast numeric columns to save memory."""
    for col in df.select_dtypes(include=["int"]).columns:
        df[col] = pd.to_numeric(df[col], downcast="integer")
    for col in df.select_dtypes(include=["float"]).columns:
        df[col] = pd.to_numeric(df[col], downcast="float")
    for col in df.select_dtypes(include=["object"]).columns:
        if df[col].nunique() / len(df) < 0.5:  # Low cardinality
            df[col] = df[col].astype("category")
    return df

# Check memory usage
print(df.memory_usage(deep=True).sum() / 1e6, "MB")
```

### Vectorized Operations (always prefer over loops)
```python
# BAD: iterating rows
for idx, row in df.iterrows():
    df.loc[idx, "profit"] = row["revenue"] - row["cost"]

# GOOD: vectorized
df["profit"] = df["revenue"] - df["cost"]

# GOOD: conditional with np.where
import numpy as np
df["status"] = np.where(df["profit"] > 0, "profitable", "loss")

# GOOD: multiple conditions with np.select
conditions = [
    df["profit"] > 1000,
    df["profit"] > 0,
    df["profit"] <= 0,
]
choices = ["high", "low", "loss"]
df["category"] = np.select(conditions, choices, default="unknown")
```

### Grouping & Aggregation
```python
# Named aggregation (pandas 2.x style)
summary = df.groupby("pool_address").agg(
    total_volume=("volume", "sum"),
    avg_fee=("fee", "mean"),
    trade_count=("id", "count"),
    last_trade=("timestamp", "max"),
).reset_index()

# Multiple operations
result = (
    df.pipe(clean_data)
      .query("volume > 0")
      .assign(fee_pct=lambda x: x["fee"] / x["volume"] * 100)
      .groupby(["pool", "date"])
      .agg({"fee_pct": ["mean", "std"], "volume": "sum"})
      .sort_values(("volume", "sum"), ascending=False)
)
```

### Time Series
```python
# Resample to daily
daily = df.set_index("timestamp").resample("1D").agg({
    "price": "ohlc",      # Open, High, Low, Close
    "volume": "sum",
})

# Rolling calculations
df["ma_7d"] = df["price"].rolling(window=7).mean()
df["volatility_30d"] = df["returns"].rolling(window=30).std() * np.sqrt(365)

# Shift for lag features
df["price_prev"] = df["price"].shift(1)
df["daily_return"] = df["price"].pct_change()
```

## numpy Patterns

```python
import numpy as np

# Array operations
prices = np.array([1800, 1850, 1790, 1920, 1880])
returns = np.diff(prices) / prices[:-1]          # Daily returns
cumulative = np.cumprod(1 + returns)              # Cumulative returns

# Linear algebra
weights = np.array([0.3, 0.5, 0.2])
portfolio_return = np.dot(weights, asset_returns)  # Weighted return

# Statistical functions
mean, std = np.mean(returns), np.std(returns)
sharpe = (mean - risk_free) / std * np.sqrt(365)  # Annualized Sharpe

# Boolean indexing
profitable = prices[prices > 1850]
mask = (prices > 1800) & (prices < 1900)
filtered = prices[mask]
```

## polars (High Performance)

```python
import polars as pl

# Lazy evaluation (optimized query plan)
result = (
    pl.scan_parquet("trades.parquet")
    .filter(pl.col("volume") > 0)
    .group_by("pool_address")
    .agg([
        pl.col("volume").sum().alias("total_volume"),
        pl.col("fee").mean().alias("avg_fee"),
        pl.col("timestamp").max().alias("last_trade"),
    ])
    .sort("total_volume", descending=True)
    .collect()  # Execute the query
)

# 10-100x faster than pandas for large datasets
```

## ETL Pipeline Pattern

```python
class DataPipeline:
    def __init__(self, source: str, destination: str):
        self.source = source
        self.destination = destination

    def extract(self) -> pd.DataFrame:
        return pd.read_parquet(self.source)

    def transform(self, df: pd.DataFrame) -> pd.DataFrame:
        return (
            df.pipe(self.clean)
              .pipe(self.enrich)
              .pipe(self.validate)
        )

    def load(self, df: pd.DataFrame):
        df.to_parquet(self.destination, index=False)

    def run(self):
        df = self.extract()
        df = self.transform(df)
        self.load(df)
        return len(df)

    @staticmethod
    def clean(df: pd.DataFrame) -> pd.DataFrame:
        return df.dropna(subset=["price"]).drop_duplicates(subset=["id"])

    @staticmethod
    def enrich(df: pd.DataFrame) -> pd.DataFrame:
        df["daily_return"] = df.groupby("pool")["price"].pct_change()
        return df

    @staticmethod
    def validate(df: pd.DataFrame) -> pd.DataFrame:
        assert df["price"].gt(0).all(), "Negative prices found"
        return df
```

## Visualization

```python
import matplotlib.pyplot as plt

# Quick plot
fig, axes = plt.subplots(2, 1, figsize=(12, 8))
df["price"].plot(ax=axes[0], title="Price History")
df["volume"].plot(ax=axes[1], title="Volume", kind="bar")
plt.tight_layout()
plt.savefig("charts/analysis.png", dpi=150)

# For interactive: use plotly
import plotly.express as px
fig = px.line(df, x="date", y="price", color="pool", title="Pool Prices")
fig.write_html("charts/interactive.html")
```

## Performance Tips

1. Use `parquet` not CSV for storage (5-10x faster I/O)
2. Use `category` dtype for low-cardinality strings
3. Avoid `iterrows()` — always vectorize
4. Use `query()` string method for filtering (faster than boolean indexing)
5. Use `pd.eval()` for complex expressions
6. Prefer `polars` or `Dask` for datasets >500MB
7. Profile with `memory_profiler` before optimizing
