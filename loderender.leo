<?xml version="1.0" encoding="utf-8"?>
<!-- Created by Leo: http://leoeditor.com/leo_toc.html -->
<leo_file xmlns:leo="http://leoeditor.com/namespaces/leo-python-editor/1.1" >
<leo_header file_format="2"/>
<globals/>
<preferences/>
<find_panel_settings/>
<vnodes>
<v t="karstenw.20210613141655.2"><vh>Script </vh>
<v t="karstenw.20210613141729.1"><vh>@clean loderender.py</vh>
<v t="karstenw.20210613142129.1"><vh>Declarations</vh></v>
<v t="karstenw.20210613142213.1"><vh>py2 / py3</vh></v>
<v t="karstenw.20210613142244.1"><vh>+ GLOBALS +</vh>
<v t="karstenw.20210714160248.1"><vh>c64colors</vh></v>
<v t="karstenw.20210714160342.1"><vh>validLodeLevelBytes</vh></v>
<v t="karstenw.20210714160414.1"><vh>rawBricks</vh></v>
</v>
<v t="karstenw.20210613142351.1"><vh>+ TOOLS +</vh>
<v t="karstenw.20210613142129.6"><vh>makeunicode</vh></v>
<v t="karstenw.20210613142129.7"><vh>hexdump</vh></v>
<v t="karstenw.20210613142129.2"><vh>makeImage</vh></v>
</v>
<v t="karstenw.20210714155339.1"><vh>+ BRICKS +</vh>
<v t="karstenw.20210613142129.3"><vh>getName</vh></v>
<v t="karstenw.20210613142129.4"><vh>dobrick</vh></v>
<v t="karstenw.20210613142129.5"><vh>getBricks</vh></v>
</v>
<v t="karstenw.20210613142403.1"><vh>+ DISK IMAGES +</vh>
<v t="karstenw.20210714160934.1"><vh>data</vh></v>
<v t="karstenw.20210613142129.10"><vh>cleanupString</vh></v>
<v t="karstenw.20210613142129.8"><vh>class VLIRFile</vh>
<v t="karstenw.20210613142129.9"><vh>__init__</vh></v>
</v>
<v t="karstenw.20210613142129.11"><vh>class GEOSDirEntry</vh>
<v t="karstenw.20210613142129.12"><vh>__init__</vh></v>
</v>
<v t="karstenw.20210613142129.13"><vh>class DiskImage</vh>
<v t="karstenw.20210613142129.14"><vh>__init__</vh></v>
<v t="karstenw.20210613142129.15"><vh>getTrackOffsetList</vh></v>
<v t="karstenw.20210613142129.16"><vh>readfile</vh></v>
<v t="karstenw.20210613142129.17"><vh>getTS</vh></v>
<v t="karstenw.20210613142129.18"><vh>getChain</vh></v>
<v t="karstenw.20210613142129.19"><vh>getDirEntries</vh></v>
</v>
</v>
<v t="karstenw.20210714203056.1"><vh>+ APPLE II DISK IMAGES #</vh></v>
<v t="karstenw.20210613142500.1"><vh>Lode Runner</vh>
<v t="karstenw.20210613142129.20"><vh>getLodeBlocks</vh></v>
<v t="karstenw.20210613142129.21"><vh>isEmptyBlock</vh></v>
<v t="karstenw.20210613142129.22"><vh>renderBlock</vh></v>
<v t="karstenw.20210714155803.1"><vh>renderCBMDisk</vh></v>
</v>
<v t="karstenw.20210714160306.1"><vh>color schemes</vh></v>
<v t="karstenw.20210613142828.1"><vh>MAIN</vh></v>
</v>
</v>
</vnodes>
<tnodes>
<t tx="karstenw.20210613141655.2"></t>
<t tx="karstenw.20210613141729.1">@language python
@tabwidth -4
@others
</t>
<t tx="karstenw.20210613142129.1">
# -*- coding: utf-8 -*-

from __future__ import print_function


import sys
import os
import io

import time
import datetime
import struct
import re
import itertools

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


</t>
<t tx="karstenw.20210613142129.10">def cleanupString( s ):
    # remove garbage
    t = s.strip( stripchars )
    t1 = bytearray( [0] )
    return t.split( t1 )[0]


</t>
<t tx="karstenw.20210613142129.11">class GEOSDirEntry(object):
    """A Commodore directory entry with additional GEOS attributes.    """

    @others
</t>
<t tx="karstenw.20210613142129.12">def __init__(self, dirEntryBytes, isGeos=True):

    if len(dirEntryBytes) == 32:
        dirEntryBytes = dirEntryBytes[2:]

    # save it for CVT file export
    self.dirEntryBytes = dirEntryBytes

    self.dosFileTypeRAW = dirEntryBytes[0]
    # self.fileOK = (ord(self.dosFileTypeRAW) &amp; 128) &gt; 0
    self.fileOK = ( self.dosFileTypeRAW &amp; 128) &gt; 0
    # self.fileProtected = (ord(self.dosFileTypeRAW) &amp; 64) &gt; 0
    self.fileProtected = ( self.dosFileTypeRAW &amp; 64) &gt; 0
    # t = ord(self.dosFileTypeRAW) &amp; 7
    t = self.dosFileTypeRAW &amp; 7

    self.fileType = dosFileTypes.get(t, "???")
    # self.trackSector = (ord(dirEntryBytes[1]), ord(dirEntryBytes[2]))
    self.trackSector = ( dirEntryBytes[1], dirEntryBytes[2] )
    self.fileName = dirEntryBytes[0x03:0x13]
    
    self.geosHeaderTrackSector = (0,0)
    # self.fileSizeBlocks = ord(dirEntryBytes[0x1c]) + ord(dirEntryBytes[0x1d]) * 256
    self.fileSizeBlocks = dirEntryBytes[0x1c] + dirEntryBytes[0x1d] * 256

    # if not geos, this is REL side sector
    # self.geosHeaderTrackSector = (ord(dirEntryBytes[19]), ord(dirEntryBytes[20]))
    self.geosHeaderTrackSector = ( dirEntryBytes[19], dirEntryBytes[20] )
    # if not geos, this is REL record size
    # self.geosFileStructure = ord(dirEntryBytes[21])
    self.geosFileStructure = dirEntryBytes[21]
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

        # self.geosFileType = ord(dirEntryBytes[22])
        self.geosFileType = dirEntryBytes[22]
        self.geosFileTypeString = geosFileTypes.get(self.geosFileType,
                            "UNKNOWN GEOS filetype:%i" % self.geosFileType)

        # self.modfDateRAW = dirEntryBytes[0x17:0x1c]
        # dates = [ord(i) for i in self.modfDateRAW]
        #dates = [ord(i) for i in self.modfDateRAW]
        #y,m,d,h,mi = dates
        y,m,d,h,mi = self.dirEntryBytes[0x17:0x1c]
        if 85 &lt;= y &lt;= 99:
            y += 1900
        else:
            y += 2000
        try:
            self.modfDate = datetime.datetime(y,m,d,h,mi)
        except Exception as err:
            self.modfDate = "ERROR WITH:  %i %i %i - %i:%i" % (y,m,d,h,mi)


</t>
<t tx="karstenw.20210613142129.13">class DiskImage(object):

    @others
# Lode Runner is saved on disk in a special way: Each level needs one disk block.
# The sectors 0 to 15 on the tracks 3 to 11 are used as well as the sectors 0 to 7
# on track 12. The last of these blocks contain the highscores.

</t>
<t tx="karstenw.20210613142129.14">def __init__(self, stream=None, filepath=None, ):
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
    
    if typ not in ('.d64', '.dsk'): # '.d71'):
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
    if py3:
        t1 = bytearray( [160] )
    else:
        t1 = chr(int("a0",16))
    s = s.rstrip( t1 )
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
        pp( (dirEntry.fileType, repr(dirEntry.fileName), len(f.chains[0])) )


</t>
<t tx="karstenw.20210613142129.15">def getTrackOffsetList(self, sizelist ):
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

</t>
<t tx="karstenw.20210613142129.16">def readfile( self, path):
    f = io.open(path, 'rb')
    s = f.read()
    f.close()
    s = bytearray(s)
    return s

</t>
<t tx="karstenw.20210613142129.17">def getTS(self, t, s):
    error = ""
    if t == 0:
        return "", ""
    try:
        # size = 256
        if self.minMaxTrack[0] &lt;= t &lt;= self.minMaxTrack[1]:
            if 0 &lt;= s &lt;= self.sectorsPerTrack[t]:
                adr = self.trackByteOffsets[t-1] + s * 256
                data = self.stream[adr:adr+256]
            else:
                return "",""
        else:
            return "",""
        
    except Exception as err:
        print("getTS(%i,%i) ERROR: %s" % (t,s,err))
        return err, ""
        # pdb.set_trace()
        print() 
        #print("adr: %s" % repr(adr) )
        #print "adr+256", adr+256
        #print len(self.stream)
        # error = err
    return error, data

</t>
<t tx="karstenw.20210613142129.18">def getChain(self, t, s):
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
            # s = ''.join( result )
            s = bytearray(result)
            return err, s
        if len(b) &lt;= 2:
            # pdb.set_trace()
            break
        tr = b[0] # ord(b[0])
        sc = b[1] # ord(b[1])
        if tr == 0:
            result.append( b[2:sc+1] )
            break
        elif (tr,sc) in readSoFar:
            # circular link
            # pdb.set_trace()
            if len(b) &gt; 2:
                result.append( b[2:] )
            break
        elif tr &gt; 80:
            break
        else:
            result.append( b[2:] )
    # s = ''.join( result )
    # s = bytearray( result )
    return error, result

</t>
<t tx="karstenw.20210613142129.19">def getDirEntries(self, t, s):
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
        
        nextrack, nextsector = b[0], b[1] # ord(b[0]), ord(b[1])
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



</t>
<t tx="karstenw.20210613142129.2">def makeImage(w, h, pixels, scale):
    """ Create a colorimage from pixels with size(w,h) and scale=scale"""

    result = {}
    byts = bytes( bytearray( pixels ) )
    if kwdbg and (len( pixels ) != 440):
        pdb.set_trace()
        print(len(pixels))
    colorimage = PIL.Image.frombytes('RGBA', (w,h), byts, decoder_name='raw')
    if scale != 1:
        size = (int(w*scale), int(h*scale) )
        colorimage = colorimage.resize( size, resample=PIL.Image.NEAREST)
    return colorimage


</t>
<t tx="karstenw.20210613142129.20">def getLodeBlocks( diskimage ):
    """Read all possible loderunner level blocks."""
    global blockTypes
    result = []
    errcount = 0

    idx = 1
    # 240 blocks
    for track in range(3, 18):
        for sector in range(16):
            err, block = diskimage.getTS( track, sector )
            if err:
                errcount += 1
                print("ERROR: %s" % repr(err))
            if kwlog:
                blockTypes.add( block[0] ) # ord(block[0]) )
            idx += 1
            result.append( (err, block, (track,sector)) )

    # track 19 - sec. 0..9
    # some disk store levels here
    track = 19
    for sector in range(10):
        err, block = diskimage.getTS( track, sector )
        if err:
            errcount += 1
            print("ERROR: %s" % repr(err) )
        if kwlog:
            blockTypes.add( block[0] ) # ord(block[0]) )
        result.append( (err, block, (track,sector)) )
    return result


</t>
<t tx="karstenw.20210613142129.21">def isEmptyBlock( block ):
    # if bytes 0..223 == 0 it might be a level block
    n = len(block)
    if n &lt; 224:
        return True
    for i in range(1, 225):
        c = block[i]
        if c not in validLodeLevelBytes:
            return False
        if c not in (0,1):
            return False
    return True


</t>
<t tx="karstenw.20210613142129.22">def renderBlock( block, bricks, scale ):
    """Render a disk block as a lode runner level PNG file.

    Returns img or False."""

    w = int(280 * scale)
    h = int(176 * scale)
    baseimg = PIL.Image.new('RGB', (w,h), backColor)

    for y in range(16):
        for xd in range( 14):
            # index into block
            i = 1 + (y * 14 + xd)
            c = block[i]
            
            # block at i consists of two tiles
            left = c &gt;&gt; 4
            right = c &amp; 15
            
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
            except Exception as err:
                print() 
                pdb.set_trace()
                print( ("xc, yc: ", xc, yc) )
                print( ("lbrick", lbrick) )
                print( ("rbrick", rbrick) )
                print( ("baseimg", baseimg) )
    return baseimg


</t>
<t tx="karstenw.20210613142129.3">def getName( comment ):
    """Extract index and name from inline brick."""
    pat = re.compile("^- (\d+) \((.+)\).*")
    m = pat.match( comment )
    if m:
        i,name = m.groups()
        i = int(i)
        return i,name
    return -1, ""


</t>
<t tx="karstenw.20210613142129.4">def dobrick( brick, transparency=1, scale=1 ):
    """Create an image for a brick.
    
    Return index, name, PIL.Image"""

    lines = brick.split( "\n" )
    comment = ""
    image = []
    for line in lines:
        if not line:
            continue
        if line[0] == '-':
            comment = line
        else:
            for c in line:
                colIdx = brickColors.get( c, -1 )
                if kwdbg and (colIdx &lt; 0):
                    print("ERROR")
                    pdb.set_trace()
                    pp(locals())
                else:
                    color = list( c64colors[colIdx] )
                    alpha = 255
                    if colIdx == 0:
                        if transparency:
                            alpha = 0
                    color.append( alpha )
                    
                    image.extend( color )
    i,c = getName( comment )
    img = makeImage( 10, 11, image, scale)
    
    if kwdbg and 1:
        # save brick as png
        img.save( str(i) + ' ' + c + '.png')
        print( ( i, c ) )
    return i, c, img


</t>
<t tx="karstenw.20210613142129.5">def getBricks( b, scale=1, transparency=1 ):
    """Create a dict with keys = brickindex and values = brickimage."""
    bricks = b.split("\n-------------\n")
    result = {}
    for brick in bricks:
        i,name,img = dobrick( brick, transparency=transparency, scale=scale )
        if i &gt;= 0:
            result[i] = (name, img)
    return result


</t>
<t tx="karstenw.20210613142129.6">def makeunicode( s, enc="utf-8", normalizer='NFC'):
    try:
        if type(s) != puni:
            s = puni(s, enc)
    except:
        pass
    s = unicodedata.normalize(normalizer, s)
    return s


</t>
<t tx="karstenw.20210613142129.7">def hexdump( s, col=32 ):
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
        if i &amp; minorMask == minorMask:
            offs = i &amp; majorMask
            
            for j in range(col):
                c2 = s[offs+j]
                d2 = ord(c2)
                if 32 &lt;= d2 &lt; 127:
                    sys.stdout.write( c2 )
                else:
                    sys.stdout.write( '.' )
            sys.stdout.write('\n')



#
# disk image tools
#

geosFileTypes = {
    0: 'Non-GEOS file',
    1: 'BASIC Program',
    2: 'Assembly program',
    3: 'Data file',
    4: 'System file',
    5: 'Desk Accessory',
    6: 'Application',
    7: 'Application Data',
    8: 'Font file',
    9: 'Printer driver',
    10: 'Input driver',
    11: 'Disk Device',
    12: 'System Boot file',
    13: 'Temporary',
    14: 'Auto Executing',
    15: 'Input 128'}


</t>
<t tx="karstenw.20210613142129.8">class VLIRFile(object):
    """The main file holding object in this suite.
    
    self.chains -   A list of GEOS VLIR strings OR just the string of any sequential
                    type in chains[0]
    self.header -   the GEOS header block. A GEOSHeaderBlock
    self.dirEntry - The CBM/GEOS dirEntry.  A GEOSDirEntry
    """

    @others
</t>
<t tx="karstenw.20210613142129.9">def __init__(self):
    self.chains = [ (0x00, 0xff) ] * 127
    self.header = ""
    self.dirEntry = ""
    # for saving
    self.folder = ""
    self.filename = ""
    # origin
    self.filepath = ""

</t>
<t tx="karstenw.20210613142213.1"># py3 stuff
py3 = False
try:
    unicode('')
    puni = unicode
    pstr = str
except NameError:
    puni = str
    pstr = bytes
    py3 = True

</t>
<t tx="karstenw.20210613142244.1">blockTypes = set()




</t>
<t tx="karstenw.20210613142351.1">#
# tools
#
</t>
<t tx="karstenw.20210613142403.1"></t>
<t tx="karstenw.20210613142500.1"></t>
<t tx="karstenw.20210613142828.1">
if __name__ == '__main__':

    # this defines the style of the image
    scale = 4
    bricks = getBricks( rawBricks, scale=scale, transparency=usealpha )

    # process the args
    for f in sys.argv[1:]:

        # get disk image
        path = os.path.abspath( f )
        folder, filename = os.path.split( path )
        basename, ext = os.path.splitext( filename )
        destfolder = os.path.join( folder, basename )
        if not os.path.exists( destfolder ):
            os.makedirs( destfolder )
        di = DiskImage( filepath=path )

        # 
        items = getLodeBlocks( di )
        print(path)
        
        renderCBMDisk(items, bricks, scale=4, usealpha=False)

    if kwlog:
        pp( blockTypes )


</t>
<t tx="karstenw.20210714155339.1"></t>
<t tx="karstenw.20210714155803.1">def renderCBMDisk(blocklist, bricks, scale=4, usealpha=False):

    for i, item in enumerate(blocklist):
        err, block, ts = item
        t,s = ts
        if isEmptyBlock( block ):
            continue
        if err:
            print(repr( err ) )
            print()
        else:
            img = renderBlock( block, bricks, scale=scale )
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


</t>
<t tx="karstenw.20210714160248.1">c64colors = {
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

</t>
<t tx="karstenw.20210714160306.1">
if 1:
    # classic c-64 loderunner color scheme
    brickCol = 14
    brickCol = 2
    runnerCol = 1
    guardCol = 3
    usealpha = True

    brickColors = {
        ' ': blackCol,
        '.': whiteCol,
        '*': brickCol,
        '#': guardCol}
    backColor = (0,0,0,1)
else:
    # black &amp; white color scheme
    brickCol = 1
    runnerCol = 0
    guardCol = 0
    usealpha = False

    brickColors = {
        ' ': whiteCol,
        '.': blackCol,
        '*': blackCol,
        '#': blackCol}
    backColor = (1,1,1,1)
</t>
<t tx="karstenw.20210714160342.1"># create a set with all possible nibble combinations (100) for fast level check
validLodeLevelNibbles = range( 10 )
validLodeLevelItems = itertools.product( validLodeLevelNibbles, repeat=2)
validLodeLevelBytes = []
for i in validLodeLevelItems:
    high, low = i
    high &lt;&lt;= 4
    byte = high + low
    validLodeLevelBytes.append( byte ) # chr(byte) )
validLodeLevelBytes = set( validLodeLevelBytes )


</t>
<t tx="karstenw.20210714160414.1">rawBricks = """-
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

</t>
<t tx="karstenw.20210714160934.1">
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
            (31, 35, 17)),
    '.dsk': (
            ( 0,  0,  0),
            ( 1, 35, 16))
    }

minMaxTrack = {
    '.dsk': (1,35),
    '.d81': (1,80),
    '.d71': (1,70),
    '.d64': (1,35) }

imagesizeToExt = {
    # filesize, ext, sector count
    143360: ( '.dsk',  560),
    174848: ( '.d64',  683),
    175531: ( '.d64',  683) }

dirSectorsForDrives = { '.d64': (18, 0) }

# TO DO: .D71
dirSectorStructures = {
    # the first entry is the struct unpack string
    # the second entry are names to be attached in a dict
    '.d64': ("&lt;b b  c      c    140s 16s 2x 2s x   2s 4x b     b     11s       5s 67x", 
             "tr sc format dosv1 bam dnam   diskid dosv2 dsktr dsksc geoformat geoversion")
}
</t>
<t tx="karstenw.20210714203056.1"></t>
</tnodes>
</leo_file>
