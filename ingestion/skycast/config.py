"""Configuration loading for SkyCast.

Reads `config.yaml` (cities + BigQuery target) and allows env-var overrides so the
same code runs locally and in Cloud Functions without changes.
"""

from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path

import yaml

DEFAULT_CONFIG_PATH = Path(__file__).resolve().parent.parent / "config.yaml"


@dataclass(frozen=True)
class City:
    name: str
    latitude: float
    longitude: float


@dataclass(frozen=True)
class Config:
    project_id: str
    dataset: str
    table: str
    forecast_days: int
    cities: list[City] = field(default_factory=list)

    @property
    def table_ref(self) -> str:
        return f"{self.project_id}.{self.dataset}.{self.table}"


def load_config(path: str | os.PathLike[str] | None = None) -> Config:
    """Load configuration from YAML, applying env-var overrides.

    GCP_PROJECT overrides the project id so the function picks up its runtime project.
    """
    config_path = Path(path) if path else DEFAULT_CONFIG_PATH
    raw = yaml.safe_load(config_path.read_text())

    project_id = os.environ.get("GCP_PROJECT") or raw["project_id"]
    bq = raw["bigquery"]
    cities = [City(**c) for c in raw["cities"]]

    return Config(
        project_id=project_id,
        dataset=os.environ.get("INBOUND_DATASET", bq["dataset"]),
        table=bq["table"],
        forecast_days=int(os.environ.get("FORECAST_DAYS", raw.get("forecast_days", 1))),
        cities=cities,
    )
