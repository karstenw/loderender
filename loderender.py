
# -*- coding: utf-8 -*-

from __future__ import print_function


import sys
import os

import datetime
import struct
import re

import zipfile
import gzip

import unicodedata

import PIL
import PIL.Image
import PIL.ImageDraw

import pprint
pp = pprint.pprint

import pdb
kwdbg = 0
kwlog = 0

import time

import itertools


# py3 stuff

py3 = False
try:
    unicode('')
    puni = unicode
    pstr = str
except NameError:
    puni = str
    pstr = bytes
    py3 = True





blockTypes = set()

#
# constants
#

c64colors = {
    0: (0,0,0),
    1: (255,255,255),
    2: (0x88,0,0),
    3: (0xaa,0xff,0xee),
    4: (0xcc,0x44,0xcc),
    5: (0x00,0xcc,0x55),
    6: (0x00,0x00,0xaa),
    7: (0xee,0xee,0x77),
    8: (0xdd,0x88,0x55),
    9: (0x66,0x44,0x00),
    10: (0xff,0x77,0x77),
    11: (0x33,0x33,0x33),
    12: (0x77,0x77,0x77),
    13: (0xaa,0xff,0x66),
    14: (0x00,0x88,0xff),
    15: (0xbb,0xbb,0xbb)}

blackCol = 0
whiteCol = 1


if 1:
    # classic c-64 loderunner color scheme
    brickCol = 14
    brickCol = 2
    runnerCol = 1
    guardCol = 3

    brickColors = {
        ' ': blackCol,
        '.': whiteCol,
        '*': brickCol,
        '#': guardCol}
    backColor = (0,0,0,1)
else:
    # black & white color scheme
    brickCol = 1
    runnerCol = 0
    guardCol = 0

    brickColors = {
        ' ': whiteCol,
        '.': blackCol,
        '*': blackCol,
        '#': blackCol}
    backColor = (1,1,1,1)



rawBricks = """-
- 0 (nothing):
          
          
          
          
          
          
          
          
          
          
          
-------------
- 1 (brick):
*****  ***
*****  ***
*****  ***
*****  ***
          
*  *******
*  *******
*  *******
*  *******
*  *******
          
-------------
- 2 (cement):
**********
**********
**********
**********
**********
**********
**********
**********
**********
**********
          
-------------
- 3 (ladder):
 ..    .. 
 ..    .. 
 ........ 
 ..    .. 
 ..    .. 
 ..    .. 
 ..    .. 
 ........ 
 ..    .. 
 ..    .. 
 ..    .. 
-------------
- 4 (rope):
          
..........
          
          
          
          
          
          
          
          
          
-------------
- 5 (false brick)
**********
**********
          
  ......  
    ..    
    ..    
    ..    
    ..    
**********
**********
          
-------------
- 6 (exit ladder)
 ..       
 ..       
 ........ 
 ..    .. 
       .. 
       .. 
       .. 
 ..    .. 
 ........ 
 ..       
 ..       
-------------
- 7 (gold):
          
          
          
          
          
  ......  
  .****.  
  .****.  
  .****.  
  ......  
          
-------------
- 8 (guard):
    #     
   ###    
   ###    
    ###   
   ### ## 
 ##  ## ##
     ##   
    ###   
   ## ####
   ##     
   ##     
-------------
- 9 (runner):
     .    
    ...   
    ...   
   ...    
 .. ...   
.. ..  .. 
   ..     
   ...    
...  ..   
     ..   
     ..   
"""

def makeImage(w, h, pixels, scale):
    # pp( (w, h, pixels) )

    result = {}
    byts = [ chr(i) for i in pixels ]
    byts = ''.join( byts )
    # byts = bytes( pixels )
    
    if len( pixels ) != 440:
        pdb.set_trace()
        print(len(pixels))
    coldummy = PIL.Image.frombytes('RGBA', (w,h), byts, decoder_name='raw')
    if scale != 1:
        size = (int(w*scale), int(h*scale) )
        coldummy = coldummy.resize( size, resample=PIL.Image.NEAREST)
    # colimg = PIL.Image.new('RGB', (w,h), (1,1,1))
    return coldummy


def getName( comment ):
    pat = re.compile("^- (\d+) \((.+)\).*")
    m = pat.match( comment )
    if m:
        i,name = m.groups()
        i = int(i)
        return i,name
    return -1, ""


def dobrick( brick, transparent=1, scale=1  ):
    lines = brick.split( "\n" )
    comment = ""
    image = []
    # pdb.set_trace()
    for line in lines:
        if not line:
            continue
        if line[0] == '-':
            comment = line
        else:
            for c in line:
                colIdx = brickColors.get( c, -1 )
                if colIdx < 0:
                    print("ERROR")
                    pdb.set_trace()
                    pp(locals())
                else:
                    color = list( c64colors[colIdx] )
                    alpha = 255
                    if colIdx == 0:
                        if transparent:
                            alpha = 0
                    color.append( alpha )
                    
                    image.extend( color )
    i,c = getName( comment )
    img = makeImage( 10, 11, image, scale)
    
    if kwdbg:
        # save brick as png
        img.save( str(i) + ' ' + c + '.png')
        print( ( i, c ) )
    return i, c, img


def getBricks( b, scale=1 ):
    bricks = b.split("\n-------------\n")
    result = {}
    for brick in bricks:
        i,name,img = dobrick( brick, scale=scale )
        img.save(name + '.png')
        if i >= 0:
            result[i] = (name, img)
    return result

dosFileTypes = {
    0: 'DEL',
    1: 'SEQ',
    2: 'PRG',
    3: 'USR',
    4: 'REL',
    5: 'CBM'}


#
# disk image constants
# 


# drive geometries
sectorTables = {
    '.d64': (
            ( 0,  0,  0),
            ( 1, 17, 21),
            (18, 24, 19),
            (25, 30, 18),
            (31, 35, 17)) }

minMaxTrack = {
    '.d81': (1,80),
    '.d71': (1,70),
    '.d64': (1,35) }

extToImagesize = {
    # ext, filesize, sector count
    '.d64': ((174848,  683),),
    '.d81': ((819200, 3200),),
    '.d71': ((349696, 1366),
             (349696+1366, 1366)) }

imagesizeToExt = {
    # filesize, ext, sector count
    174848: ( '.d64',  683),
    175531: ( '.d64',  683) }

dirSectorsForDrives = { '.d64': (18, 0) }

# TO DO: .D71
dirSectorStructures = {
    # the first entry is the struct unpack string
    # the second entry are names to be attached in a dict
    '.d64': ("<b b  c      c    140s 16s 2x 2s x   2s 4x b     b     11s       5s 67x", 
             "tr sc format dosv1 bam dnam   diskid dosv2 dsktr dsksc geoformat geoversion")
}


#
# tools
#
def makeunicode( s, enc="utf-8", normalizer='NFC'):
    try:
        if type(s) != unicode:
            s = unicode(s, enc)
    except:
        pass
    s = unicodedata.normalize(normalizer, s)
    return s


def hexdump( s, col=32 ):
    """Using this for debugging was so memory lane..."""

    cols = {
         8: ( 7, 0xfffffff8),
        16: (15, 0xfffffff0),
        32: (31, 0xffffffe0),
        64: (63, 0xffffffc0)}

    if not col in cols:
        col = 16
    minorMask, majorMask = cols.get(col)
    d = False
    mask = col-1
    if type(s) in( list, tuple): #ImageBuffer):
        d = True
    for i,c in enumerate(s):
        if d:
            t = hex(c)[2:]
        else:
            t = hex(ord(c))[2:]
        t = t.rjust(2, '0')

        # spit out address
        if i % col == 0:
            a = hex(i)[2:]
            a = a.rjust(4,'0')
            sys.stdout.write(a+':  ')
        sys.stdout.write(t+' ')

        # spit out ascii line
        if i & minorMask == minorMask:
            offs = i & majorMask
            
            for j in range(col):
                c2 = s[offs+j]
                d2 = ord(c2)
                if 32 <= d2 < 127:
                    sys.stdout.write( c2 )
                else:
                    sys.stdout.write( '.' )
            sys.stdout.write('\n')



#
# disk image tools
#

class VLIRFile(object):
    """The main file holding object in this suite.
    
    self.chains -   A list of GEOS VLIR strings OR just the string of any sequential
                    type in chains[0]
    self.header -   the GEOS header block. A GEOSHeaderBlock
    self.dirEntry - The CBM/GEOS dirEntry.  A GEOSDirEntry
    """

    def __init__(self):
        self.chains = [ (0x00, 0xff) ] * 127
        self.header = ""
        self.dirEntry = ""
        # for saving
        self.folder = ""
        self.filename = ""
        # origin
        self.filepath = ""

def cleanupString( s ):
    # remove garbage
    t = s.strip( stripchars )
    return t.split( chr(0) )[0]


class GEOSDirEntry(object):
    """A Commodore directory entry with additional GEOS attributes.    """

    def __init__(self, dirEntryBytes, isGeos=True):
    
        if len(dirEntryBytes) == 32:
            dirEntryBytes = dirEntryBytes[2:]

        # save it for CVT file export
        self.dirEntryBytes = dirEntryBytes

        self.dosFileTypeRAW = dirEntryBytes[0]
        self.fileOK = (ord(self.dosFileTypeRAW) & 128) > 0
        self.fileProtected = (ord(self.dosFileTypeRAW) & 64) > 0
        t = ord(self.dosFileTypeRAW) & 7

        self.fileType = dosFileTypes.get(t, "???")
        self.trackSector = (ord(dirEntryBytes[1]), ord(dirEntryBytes[2]))
        self.fileName = dirEntryBytes[0x03:0x13]
        
        self.geosHeaderTrackSector = (0,0)
        self.fileSizeBlocks = ord(dirEntryBytes[0x1c]) + ord(dirEntryBytes[0x1d]) * 256

        # if not geos, this is REL side sector
        self.geosHeaderTrackSector = (ord(dirEntryBytes[19]), ord(dirEntryBytes[20]))
        # if not geos, this is REL record size
        self.geosFileStructure = ord(dirEntryBytes[21])
        self.geosFileStructureString = ""
        self.geosFileTypeString = ""
        self.modfDate = "NO MODF DATE"
        self.isGEOSFile = False

        if self.fileType == 'USR':
            if self.geosFileStructure == 0:
                self.geosFileStructureString = "Sequential"
                self.isGEOSFile = True
            elif self.geosFileStructure == 1:
                self.geosFileStructureString = "VLIR"
                self.isGEOSFile = True

            self.geosFileType = ord(dirEntryBytes[22])
            #self.geosFileTypeString = geosFileTypes[self.geosFileType]
            self.geosFileTypeString = geosFileTypes.get(self.geosFileType,
                                    "UNKNOWN GEOS filetype:%i" % self.geosFileType)

            self.modfDateRAW = dirEntryBytes[0x17:0x1c]
            dates = [ord(i) for i in self.modfDateRAW]
            y,m,d,h,mi = dates
            if 85 <= y <= 99:
                y += 1900
            else:
                y += 2000
            try:
                self.modfDate = datetime.datetime(y,m,d,h,mi)
            except Exception, err:
                self.modfDate = "ERROR WITH:  %i %i %i - %i:%i" % (y,m,d,h,mi)


class DiskImage(object):

    def __init__(self, stream=None, filepath=None, ):
        # alternate path for streams
        self.filepath = ""
        self.stream = ""
        if filepath:
            if os.path.exists( filepath ):
                self.filepath = os.path.abspath(os.path.expanduser(filepath))
                self.stream = self.readfile( self.filepath )
            else:
                print("No File ERROR!")
                # pdb.set_trace()
        elif stream:
            self.stream = stream
        else:
            # pdb.set_trace()
            print()
        self.isOK = False
        self.files = []
        size = len(self.stream)
        typ, sectorcount = imagesizeToExt.get( size, ("",0) )
        
        if typ not in ('.d64',): # '.d71'):
            return

        self.isOK = True

        o,p,t = self.getTrackOffsetList( sectorTables[typ] )
        self.sectorOffsets, self.trackByteOffsets, self.sectorsPerTrack = o,p,t
        self.dirSectorTS = dirSectorsForDrives.get(typ, (0,0))

        self.minMaxTrack = minMaxTrack[typ]

        dtr, dsc = self.dirSectorTS
    
        s,n = dirSectorStructures[typ]
        err, dirSec = self.getTS( dtr, dsc )
        #if err != "":
        #    pdb.set_trace()
        t = struct.unpack(s, dirSec)
        n = n.split()
        d = dict(zip(n,t))
        s = d.get('dnam', 'NO DISK NAME')
        s = s.rstrip( chr(int("a0",16)))
        self.diskName = s
    
        err, self.DirEntries = self.getDirEntries( d['tr'], d['sc'])
        
        # get files
        dirEntries = self.DirEntries[:]

        for dirEntry in dirEntries:
            # 
            f = VLIRFile()
            f.dirEntry = dirEntry
            f.header = ""

            # file content
            t,s = dirEntry.trackSector
            err, f.chains[0] = self.getChain(t, s)

            self.files.append( f )


    def getTrackOffsetList(self, sizelist ):
        """calculate sectorOffset per Track, track Byte offstes and
           sectors per track lists."""

        offset = 0
        sectorsize=256
        sectorOffsets = []
        trackByteOffsets = []
        sectorsPerTrack = []
        for start, end, sectors in sizelist:
            for track in range(start, end+1):
                offset += sectors 
                sectorOffsets.append(offset)
                sectorsPerTrack.append( sectors )
        for start, end, sectors in sizelist:
            for track in range(start, end+1):
                if track == 0:
                    continue
                trackByteOffsets.append( (sectorOffsets[track-1]) * sectorsize )
        return sectorOffsets, trackByteOffsets, sectorsPerTrack

    def readfile( self, path):
        f = open(path, 'rb')
        s = f.read()
        f.close()
        return s

    def getTS(self, t, s):
        error = ""
        if t == 0:
            return "", ""
        try:
            # size = 256
            if self.minMaxTrack[0] <= t <= self.minMaxTrack[1]:
                if 0 <= s <= self.sectorsPerTrack[t]:
                    adr = self.trackByteOffsets[t-1] + s * 256
                    data = self.stream[adr:adr+256]
                else:
                    return "",""
            else:
                return "",""
            
        except Exception, err:
            print("getTS(%i,%i) ERROR: %s" % (t,s,err))
            return err, ""
            # pdb.set_trace()
            print() 
            #print("adr: %s" % repr(adr) )
            #print "adr+256", adr+256
            #print len(self.stream)
            # error = err
        return error, data
    
    def getChain(self, t, s):
        error = ""
        readSoFar = set()
        # pdb.set_trace()
        result = []
        tr, sc = t, s
        blocks = 0
        while True:
            blocks += 1
            err, b = self.getTS(tr, sc)
            readSoFar.add( (tr,sc) )
            if err != "":
                s = ''.join( result )
                return err, s
            if len(b) <= 2:
                # pdb.set_trace()
                break
            tr = ord(b[0])
            sc = ord(b[1])
            if tr == 0:
                result.append( b[2:sc+1] )
                break
            elif (tr,sc) in readSoFar:
                # circular link
                # pdb.set_trace()
                if len(b) > 2:
                    result.append( b[2:] )
                break
            elif tr > 80:
                break
            else:
                result.append( b[2:] )
        return error, ''.join( result )

    def getDirEntries(self, t, s):
        """Read all file entries"""
        readSoFar = set()
        error = ""
        result = []
        if t == 0:
            return "", result
        nextrack, nextsector = t, s
        while True:
            readSoFar.add( (nextrack, nextsector) )
            err, b = self.getTS( nextrack, nextsector)
            if err != "":
                break
                # return err, result
            if not b:
                break
            
            nextrack, nextsector = ord(b[0]), ord(b[1])
            if (nextrack, nextsector) in readSoFar:
                break
            base = 0
            for i in range(8):
                offset = i * 32
                dirEntryRaw = b[offset:offset+32]
                gde = GEOSDirEntry(dirEntryRaw)
                if gde.fileType in ( 'SEQ', 'PRG', 'USR'):
                    result.append( gde )
        return error, result



# Lode Runner is saved on disk in a special way: Each level needs one disk block.
# The sectors 0 to 15 on the tracks 3 to 11 are used as well as the sectors 0 to 7
# on track 12. The last of these blocks contain the highscores.

def getLodeBlocks( diskimage ):
    global blockTypes
    result = []
    errcount = 0
    # pdb.set_trace()

    idx = 1
    # 240 blocks
    for track in range(3, 18):
        for sector in range(16):
            err, block = diskimage.getTS( track, sector )
            if err:
                errcount += 1
                print("ERROR: %s" % repr(err))
            if kwlog:
                blockTypes.add( ord(block[0]) )
            idx += 1
            if 0: #idx > 150:
                pdb.set_trace()
                print()
            result.append( (err, block, (track,sector)) )

    # not needed with extended scan in first loop
    if 0:
        track = 12
        for sector in range(6):
            err, block = diskimage.getTS( track, sector )
            if err:
                errcount += 1
                print("ERROR: %s" % repr(err) )
            if kwlog:
                blockTypes.add( ord(block[0]) )
            result.append( (err, block, (track,sector)) )

    # track 19 - sec. 0..9
    # some disk store levels here
    if 1:
        track = 19
        for sector in range(10):
            err, block = diskimage.getTS( track, sector )
            if err:
                errcount += 1
                print("ERROR: %s" % repr(err) )
            if kwlog:
                blockTypes.add( ord(block[0]) )
            result.append( (err, block, (track,sector)) )
    return result


def canBeLodeLevelBlock( block ):
    # count nibbletypes and compare
    pass


def isEmptyBlock( block ):
    
    # if bytes 0..223 == 0 it might be a level block
    n = len(block)
    if n < 224:
        return True
    for i in range(1, 225):
        c = block[i]
        if c not in validLodeLevelBytes:
            return False
        s = ord(c)
        if s not in ( 0, 1):
            return False
    return True


def renderBlock( block, scale ):
    """Render a disk block as a lode runner level PNG file.
    
    Returns img or False."""
    w = int(280 * scale)
    h = int(176 * scale)
    baseimg = PIL.Image.new('RGB', (w,h), backColor)
    chk = ord( block[0] )
    
    #if chk not in (0,1,3,13):
    #    return False
    # pdb.set_trace()
    for y in range(16):
        for xd in range( 14):
            # index into block
            i = 1 + (y * 14 + xd)

            c = ord(block[i])
            
            # block at i consists of two tiles
            left = c >> 4
            right = c & 15
            
            _, lbrick = bricks.get( left, ("","") )
            _, rbrick = bricks.get( right, ("","") )
            if lbrick ==  "":
                return False
            if rbrick ==  "":
                return False
            yc = int(y * 11 * scale)
            xc = int(xd * 20 * scale)
            offset = int(10 * scale)
            try:
                baseimg.paste( lbrick, (xc+offset,yc) )
                baseimg.paste( rbrick, (xc+000000,yc) )
            except Exception, err:
                print() 
                pdb.set_trace()
                print( ("xc, yc: ", xc, yc) )
                print( ("lbrick", lbrick) )
                print( ("rbrick", rbrick) )
                print( ("baseimg", baseimg) )
    return baseimg


scale = 2
bricks = getBricks(rawBricks, scale=scale)

validLodeLevelNibbles = range( 10 )
# validLodeLevelNibbles = [ chr(i) for i in validLodeLevelNibbles ]
validLodeLevelItems = itertools.product( validLodeLevelNibbles, repeat=2)
validLodeLevelBytes = []
for i in validLodeLevelItems:
    high, low = i
    high <<= 4
    byte = high + low
    validLodeLevelBytes.append( chr(byte) )
validLodeLevelBytes = set( validLodeLevelBytes )


if __name__ == '__main__':
    for f in sys.argv[1:]:
        # pdb.set_trace()
        path = os.path.abspath( f )
        folder, filename = os.path.split( path )
        basename, ext = os.path.splitext( filename )
        destfolder = os.path.join( folder, basename )
        if not os.path.exists( destfolder ):
            os.makedirs( destfolder )
        di = DiskImage( filepath=path )
        items = getLodeBlocks( di )
        print(path)
        for i, item in enumerate(items):
            err, block, ts = item
            t,s = ts
            if isEmptyBlock( block ):
                continue
            if err:
                print(repr( err ) )
                print()
            else:
                img = renderBlock( block, scale=scale )
                if not img:
                    continue
                basename = "level %i (%i,%i)" % (i+1,t,s)
                name = basename + ".png"
                destimage = os.path.join( destfolder, name )
                # img = img.convert("P")
                img.save( destimage )
                if 1: #kwlog:
                    print(basename)
            # hexdump( block )
    if kwlog:
        pp( blockTypes )


