# GraphHopper tool

This directory isolates the local GraphHopper runtime from the Rails application.

## Layout

- `compose.yml`: local Docker Compose entrypoint
- `Dockerfile`: local GraphHopper image definition
- `graphhopper.yml`: GraphHopper server configuration baked into the image
- `graphhopper-web-*.jar`: downloaded GraphHopper server jar placed in this directory before build
- `data/`: put the `.osm.pbf` you want to import here
- `graph-cache/`: generated routing graph cache
- `srtm/`: downloaded elevation cache
- `logs/`: GraphHopper logs

These directories are checked in with `.keep` files so the bind mounts already exist before the first `docker compose up`.

## Usage

1. Put your region PBF into `data/`.
2. Put the downloaded `graphhopper-web-*.jar` in this directory.
3. Point `data/region.osm.pbf` at the actual file, for example `ln -sfn kanto-260521.osm.pbf data/region.osm.pbf`.
4. If `region.osm.pbf` now points to a different source PBF than before, clear `graph-cache/` before restart.
5. From this directory run `docker compose -f compose.yml up --build`.

The first startup imports the PBF and can take significant time and disk space. After the graph cache exists, restarts are much faster.

If startup fails during elevation import with an error like `Unexpected end of ZLIB input stream`, remove the broken file under `srtm/` and start again so GraphHopper can download that tile again.

If you change `graphhopper.yml` or replace the JAR, rebuild the image with `docker compose -f compose.yml up --build`.

If you switch datasets by repointing `data/region.osm.pbf`, remove the existing files under `graph-cache/` so GraphHopper rebuilds the import from the new PBF.

Phloem reaches this service via `http://localhost:8989` by default, so no Rails configuration change is required for local development.
