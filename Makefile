ty:
	uv run ty check ./producer/

black:
	uv run black --check ./producer/

black-fix:
	uv run black ./producer/

ruff:
	uv run ruff check producer/ --fix

lint:
	make ty & make black-fix & make ruff