---
paths:
  - "Code/Python/**/*.py"
  - "scripts/**/*.py"
---

# Python Code Standards (Geodata)

**Standard:** Senior GIS engineer + spatial econometrics quality

---

## 1. Reproducibility

- Set `random_state=` explicitly for any stochastic operation (clustering, resampling)
- All paths relative to repository root; use `pathlib.Path` not string concatenation
- Pin package versions in `requirements.txt` (especially GDAL, rasterio, geopandas)
- `if __name__ == "__main__":` guard on all executable scripts

## 2. CRS Protocol (MANDATORY)

CRS mismatches are the #1 silent error in geodata work. Treat as critical.

```python
import geopandas as gpd

# Always check before any spatial join or overlay
assert gdf_a.crs == gdf_b.crs, f"CRS mismatch: {gdf_a.crs} vs {gdf_b.crs}"

# Always reproject to a common CRS first
TARGET_CRS = "EPSG:4326"   # or EPSG:32650 (UTM zone 50N) for China
gdf = gdf.to_crs(TARGET_CRS)

# Always set CRS when creating from scratch
gdf = gpd.GeoDataFrame(df, geometry="geometry", crs=TARGET_CRS)
```

**Standard CRS for this project:**
- Geographic: `EPSG:4326` (WGS84) — for merging and storage
- Projected: `EPSG:32650` (UTM Zone 50N) or `EPSG:32651` (UTM Zone 51N) — for area/distance
- Chinese national standard: `EPSG:4479` (CGCS2000) — match admin boundary data

## 3. Memory Management (Large Rasters)

```python
import rasterio

# Always use context manager — closes file handle automatically
with rasterio.open("path/to/raster.tif") as src:
    data = src.read(1)
    meta = src.meta

# For very large rasters: read by window
from rasterio.windows import Window
with rasterio.open("path/to/large.tif") as src:
    window = Window(col_off=0, row_off=0, width=1000, height=1000)
    data = src.read(1, window=window)
```

## 4. Output Conventions

```python
from pathlib import Path

# Processed data → Data/processed/
PROCESSED_DIR = Path("Data/processed")
PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
gdf.to_file(PROCESSED_DIR / "county_cropland.gpkg")   # GeoPackage > Shapefile

# Figures → Results/Figures/
FIGURES_DIR = Path("Results/Figures")
FIGURES_DIR.mkdir(parents=True, exist_ok=True)
fig.savefig(FIGURES_DIR / "figure_name.pdf", dpi=300, bbox_inches="tight")

# Tables → Results/Tables/
TABLES_DIR = Path("Results/Tables")
df.to_csv(TABLES_DIR / "summary_stats.csv", index=False)
```

**Prefer GeoPackage (`.gpkg`) over Shapefile (`.shp`):** single file, no 10-char column limit, supports larger datasets.

## 5. Satellite Data Conventions

```python
# Always document band order at top of script
# Example: Landsat 8 OLI
# Band 1: Coastal/Aerosol | Band 2: Blue | Band 3: Green
# Band 4: Red | Band 5: NIR | Band 6: SWIR1 | Band 7: SWIR2

# NDVI calculation — always verify band indices match sensor
def compute_ndvi(nir_band, red_band):
    """Compute NDVI from NIR and Red bands. Output range: [-1, 1]."""
    nir  = nir_band.astype("float32")
    red  = red_band.astype("float32")
    ndvi = (nir - red) / (nir + red + 1e-10)  # epsilon avoids div by zero
    return ndvi.clip(-1, 1)
```

## 6. Common Pitfalls

| Pitfall | Impact | Prevention |
|---------|--------|------------|
| CRS not checked before join | Silent wrong merge | Assert CRS equality before every join |
| Shapefile truncates column names to 10 chars | Lost field names | Use GeoPackage instead |
| Reading full raster into memory | OOM crash | Use windowed reads or COG format |
| GDAL version mismatch | Inconsistent CRS transforms | Pin GDAL in requirements.txt |
| Missing `bbox_inches="tight"` | Clipped figure | Always include in savefig() |
| Int16 overflow in band math | Wrong index values | Cast to float32 before arithmetic |

## 7. Code Quality Checklist

```text
[ ] Imports at top; no inline imports
[ ] All paths via pathlib.Path (not hardcoded strings)
[ ] CRS verified before every spatial join
[ ] Rasters opened via context manager
[ ] random_state= set for stochastic operations
[ ] Output directories created with mkdir(parents=True, exist_ok=True)
[ ] Band order documented in comments
[ ] requirements.txt includes pinned geodata packages
[ ] __name__ == "__main__" guard
```
