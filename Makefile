ty:
	uv run ty check ./producer/ ./processing/

black:
	uv run black --check ./producer/ ./processing/

black-fix:
	uv run black ./producer/ ./processing/

ruff:
	uv run ruff check producer/ processing/ --fix

lint:
	make ty & make black-fix & make ruff