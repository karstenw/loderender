### loderender



loderender is a Python script that renders [Lode Runner](https://en.wikipedia.org/wiki/Lode_Runner) Levels on C-64 disk images as png files.

This project was a weekend hack. The documentation is non-existent and many code lines were ripped out of [geosLib](https://github.com/karstenw/geosLib).


#### Usage:

python loderender.py LoderunnerDiskImage.d64


This creates a folder named "LoderunnerDiskImage" and renders all the levels it can find on the disc image.


#### Requirements

- Python 2.7 or Python 3. Tested with 2.7.16 and 3.8.7

- [Pillow](https://pypi.org/project/Pillow/)


![level 1](./images/level_1.png?raw=True)
