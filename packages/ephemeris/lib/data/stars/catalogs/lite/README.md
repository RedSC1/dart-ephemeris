# Lite TSC1 Star Catalog

`stars-bright-v5.tsc1` is the distribution-sized fixed-star catalog. Its
ordinary bright-star layer contains every available record with catalogue
visual magnitude `V <= 5.0`. It then adds:

- all HIP stars used by the line figures in Stellarium's Chinese sky culture;
- all HIP stars used by the twelve western zodiac line figures;
- Taiyin's two manual special-direction records, `galactic_center_j2000` and
  `sgr_a_apparent`.

The cultural selection is generated from Stellarium sky-cultures revision
`014fbb5e59233d133c22f9811af96b67d05a95c9`. It contains 1,385 Chinese
line stars and 141 western-zodiac line stars, or 1,399 unique HIP identifiers
after overlap. Unambiguous English and Simplified Chinese traditional star
names are retained as aliases, including names such as `织女一`, `角宿一`, and
`毕宿一`. Twelve aliases shared by more than one HIP star are omitted because
TSC1 alias lookup is intentionally one-to-one.

The Stellarium-derived cultural selection and names are provided under
CC BY-SA. The astrometric records retain their original Gaia DR3, Hipparcos,
BSC5, or manual provenance. See `required_stars.json` for the pinned source
revision and the exact generated selection.

Current contents:

| Catalog | Stars | Aliases | File size |
| --- | ---: | ---: | ---: |
| `stars-bright-v5.tsc1` | 2,057 | 12,242 | about 0.56 MB |
| `../stars-bright-gaia-bsc.tsc1` | 9,098 | 37,527 | about 1.9 MB |
| `../stars-hipparcos-gaia.tsc1` | 118,059 | 328,594 | about 21 MB |

This Dart distribution includes only the lite catalog. The larger catalogs
and the maintainer generation tools live in the Taiyin C++ source repository:

<https://github.com/RedSC1/taiyin-ephemeris>

Maintainers regenerate `required_stars.json` from the pinned upstream Chinese
and western `index.json` files and Chinese `po/zh_CN.po`, then filter the full
Hipparcos/Gaia TSC1 table by V-band magnitude and required HIP membership. The
exact commands are documented beside the generation tools in the C++ source
repository. They are intentionally not duplicated in this installed package.

The filter preserves selected astrometry and ordinary aliases. It does not
refit stellar positions.
