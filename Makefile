ty:
	uv run ty check $(app)

black:
	uv run black --check $(app) 

black-fix:
	uv run black $(app)

ruff:
	uv run ruff check $(app) --fix

lint:
	make ty app=$(app) & make black-fix app=$(app) & make ruff app=$(app)