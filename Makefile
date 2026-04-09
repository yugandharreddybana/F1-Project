.PHONY: help install download extract profile upload load-raw staging marts presentation pipeline clean test

help:
	@echo "F1 Analytics Platform — available targets:"
	@echo ""
	@echo "  make install     Install Python dependencies"
	@echo "  make download    Download Ergast F1 dataset from Kaggle into data/raw/"
	@echo "  make extract     Extract dataset from a local zip file (default: F1_Dataset.zip)"
	@echo "  make profile     Profile every CSV, write docs/data_profile.md"
	@echo "  make upload      Upload all CSVs to Google Cloud Storage"
	@echo "  make load-raw    Load CSVs into BigQuery f1_raw dataset (typed)"
	@echo "  make staging     Build f1_staging views"
	@echo "  make marts       Build f1_marts star schema tables"
	@echo "  make presentation Build f1_presentation layer for BI tools"
	@echo "  make pipeline    Run profile → upload → load-raw → staging → marts → presentation"
	@echo "  make test        Run row-count sanity tests"
	@echo "  make clean       Remove cached and downloaded data"

install:
	pip install -r requirements.txt

DATASET_ZIP ?= F1_Dataset.zip

download:
	@mkdir -p data/raw
	kaggle datasets download -d rohanrao/formula-1-world-championship-1950-2020 \
		-p data/raw --unzip
	@echo "Downloaded $$(ls data/raw/*.csv | wc -l) CSV files"

extract:
	@mkdir -p data/raw
	@if [ -f "$(DATASET_ZIP)" ]; then \
		unzip -o "$(DATASET_ZIP)" -d data/raw; \
		echo "Extracted $$(ls data/raw/*.csv | wc -l) CSV files from $(DATASET_ZIP)"; \
	else \
		echo "ERROR: $(DATASET_ZIP) not found. Place it in the project root or use ZIP_PATH=..."; \
		exit 1; \
	fi

profile:
	python scripts/profile_data.py

upload:
	python scripts/upload_to_gcs.py

load-raw:
	python scripts/load_raw_to_bq.py

staging:
	python scripts/run_sql.py sql/staging

marts:
	python scripts/run_sql.py sql/marts

presentation:
	python scripts/run_sql.py sql/presentation

pipeline: profile upload load-raw staging marts presentation
	@echo ""
	@echo "Pipeline complete. Connect Looker Studio to f1_marts to build the dashboard."

test:
	python -m pytest tests/ -v

clean:
	rm -rf data/raw/*.csv data/raw/*.zip
	rm -rf __pycache__ scripts/__pycache__ tests/__pycache__
	rm -f docs/data_profile.md
