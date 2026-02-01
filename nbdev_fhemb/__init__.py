__version__ = "0.0.1"

import os, plotly.io as pio
if os.getenv("GITHUB_ACTIONS"):
    pio.renderers.default = "png"
