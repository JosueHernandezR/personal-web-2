.PHONY: install dev test lint format migration

# Installation
install:
	curl -LsSf https://astral.sh/uv/install.sh | sh
	~/.cargo/bin/uv pip install --no-cache .

# Development
dev:
	uvicorn app.main:app --reload

# Testing
test:
	pytest tests/ -v --cov=app

# Linting and formatting
lint:
	ruff check .
	mypy .

format:
	ruff format .
	black .

# Database migrations
migration:
	alembic revision --autogenerate -m "$(message)"

migrate:
	alembic upgrade head

migrate-down:
	alembic downgrade -1

# Docker commands
docker-build:
	docker build -t fastapi-backend .

docker-run:
	docker run -p 8888:8000 --env-file .env fastapi-backend

# Development setup
setup-dev: install
	pre-commit install
	~/.cargo/bin/uv pip install --no-cache -e ".[dev]"