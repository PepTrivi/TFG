#!/usr/bin/python

"""
TaskSim to McPat script
"""
import sys
import re
import collections
from optparse import OptionParser
from jinja2 import Environment
from jinja2 import FileSystemLoader

# GLOBAL variables
TEMPLATE = 'mcpat-input.xml'
TEMPLATE_DIR = 'templates'
TOTALCYC = 'Finalcyclecount'
ACC_TYP = 'access_type'
PRECONF = 'configure'
PRESYS = 'system'
LVLCACHE = {'DL1Cache', 'L2Cache'}
CORES = 0
CACHE3 = 0
PRIVATEL2 = 0
            
# In order to add the information to the Jinja2 template, it is needed to
# create a collection.
# This dictionary has to levels
#     1st level: System (information from the results file and it is
#                global information for the whole system.
#                Configure (information from the configuration file.
#                Core (information from the results file and it is just 
#                for a specific core.
#     2n level: Information name (totalmisses, write_miss...)

class Statistics(collections.MutableMapping):
    def __init__(self, data={}):
        self.data = {}
        
    def __getitem__(self, key):
        return self.data.get(key, 0)
      
    def __setitem__(self, key, value):
        self.data[key] = value
        
    def __delitem__(self, key):
        self.data.pop(key)
    
    def __iter__(self):
        return iter(self.data)
    
    def __len__(self):
        return len(self.data)
    
    # insert a value, if the key doesn't exist, create it.
    def insert(self, key, attr, value):
        try:
            self.data[key][attr] = value
        except KeyError:
            self.data[key]= {}
            self.data[key][attr] = value
 
    # get a value given a key and an attribute.
    def get(self, key, attr):
        return self.data[key][attr]
   
   # add a value to the value on the dictionary.
    def add(self, key, attr, value):
        aux = self.data[key][attr]
        self.data[key][attr]= value + aux
    
# Calculate the total reads and total writes. Moreover, add the
# read misses into the write hits (we need a read miss to be written to the cache).
def _modify(results, key, attr):
    write_hit = '{}_write_hit'.format(attr)
    wm = results.get(key, '{}_write_miss'.format(attr))
    whm = results.get(key, '{}_write_half_miss'.format(attr))
    rhm = results.get(key, '{}_read_half_miss'.format(attr))
    rm = results.get(key, '{}_read_miss'.format(attr))
    rh = results.get(key, '{}_read_hit'.format(attr))
    wh = results.get(key, write_hit)
    totalread = rh + rm + rhm
    totalwrite = wm + wh + whm + rm
    results.add(key, write_hit, rm)
    results.insert(key, '{}_totalread'.format(attr), totalread)
    results.insert(key, '{}_totalwrite'.format(attr), totalwrite)  
  
# Calculate the read/write statistics for each cache
def _get_rw_statistics(results):
    # For each core and for each cache level inside of the core.    
    # If cache l2 is private, there has to be just one cache L2.
    if PRIVATEL2 == '0':  
        _modify(results, PRESYS, 'L2Cache')
        for core in range(0, CORES):
            key = 'core{}'.format(core)
            _modify(results, key,'DL1Cache')
    else:
        for core in range(0, CORES):
            key = 'core{}'.format(core)
            for lvl in LVLCACHE:
                _modify(results, key, lvl)
    
    # If there is a lvl Cache 3, this level has to be added to the statistics.
    if CACHE3 == 1:
        _modify(results, PRESYS, 'L3Cache')
        
    results.insert(PRESYS, 'existsL3', CACHE3)    
    results.insert(PRESYS, 'privateL2', PRIVATEL2) 
    
# Transformations in order to know from which cache the data comes from.
def _cacheld1(num):
    if PRIVATEL2 == '1':
        return int((int(num)*0.5) - CORES)
    else:
        return int((int(num)) - CORES*2)
  
def _cacheld2(num):
        return _cacheld1(int(num)-1)

def _memory(num):
        return int((int(num)-1)*0.5)   

# Format the data.
def _trans(typ, numcore):
    if(typ == 'Cache'):
        if PRIVATEL2 == '1':
            # If L2 is private, then every core has his own L2. L2 has unpair value and L1 has the pair value.
            if(int(numcore)%2 != 0):
                return 'core{}'.format(_cacheld2(numcore)), 'L2Cache_'
            elif(int(numcore) == CORES*4):
                return PRESYS, 'L3Cache_'
            else: 
                return 'core{}'.format(_cacheld1(numcore)), 'DL1Cache_'
        else:
            # If L2 is shared, then there is only one.
            if(int(numcore) == (CORES*3)):
                return PRESYS, 'L2Cache_'   
            elif(int(numcore) == (CORES*3 + 1)):
                return PRESYS, 'L3Cache_'
            else:
                return 'core{}'.format(_cacheld1(numcore)), 'DL1Cache_'
       
    elif(typ == 'Memory'):
        return 'core{}'.format(_memory(numcore)), 'Memory'
    elif(typ == 'ROA' or typ == 'Burst'):
        return 'core{}'.format(numcore), typ
    elif(typ == 'Bus' or typ == 'DRAM'):
        return PRESYS, typ
    return ""

# MSHR size comes into a different field, it is necessary to find the field
# and insert it inside the cache.
def _match_mhrs(results, mhrs_list):
    for key in mhrs_list.keys():
        value = results.get(PRECONF, mhrs_list[key] + "_size")
        results.insert(PRECONF,key , value)


# Load the results from the configuration file. These values are from the configuration
# file of TaskSim. These values have the prefix Configure.
def _stats_load(results, stfile):
    global CORES
    mhrs_list = {}
    preaux = ""
    ignores = re.compile(r'#')
    with open(stfile) as lines:
        for line in lines:
            if line:
                if not ignores.match(line): 
                    line = line.replace(' ', '').replace('\n', '').replace('[', '').replace(']', '').replace('-','')
                    line = re.split('=', line)
                    if len(line) == 1:
                        preaux = '{}_'.format(line[0])
                    else:
                        if line[1].isdigit():
                            results.insert(PRECONF, preaux + line[0], int(line[1]))
                        else:
                            if(line[0] == 'mshr'):
                                mhrs_list[preaux + line[0]] = line[1]
                            else:
                                results.insert(PRECONF, preaux + line[0], line[1])
    CORES = results.get(PRECONF, 'ncpus')
    _match_mhrs(results, mhrs_list)


# Load the results from the results.txt. These values are the results from the TaskSim execution.
# These values have the prefix System if they are used for the whole system or core(NUM) if
# they are used for a specific core.
def _results_load(results, resfile):
    ignores = re.compile(r'#') 
    with open(resfile) as lines:
        for line in lines:
            if line:
                if not ignores.match(line):    
                    line = line.replace(' ', '').replace('\n', '')
                    lineaux = re.split(":", line)
                    if (re.compile(TOTALCYC)).search(line):                  #Format: ['Finalcyclecount', '6234246']. Read the total number of cycles
                        value = lineaux[1]
                        results.insert(PRESYS, TOTALCYC, int(value))
                    elif(lineaux[0].isdigit() and len(lineaux) == 4):        #Format: ['299730', 'ROAtotalnumberofstores', 'ROA', '0']. Read the number of comitted instructions for example.
                        key, attr = _trans(lineaux[2], lineaux[3])
                        value = lineaux[0]
                        results.insert(key, attr + lineaux[1], int(value))
    _get_rw_statistics(results)


# Use jinja2 to plot the statistics into the template.
def _template_load(results, temfile, path, outfile):
    env = Environment(loader=FileSystemLoader(path))
    template = env.get_template(temfile)
    aux = template.render(results=results)
    with open(outfile, 'w') as f:  
        f.write(aux)
    f.close
    
######### Main         
def main():
    global CACHE3
    global PRIVATEL2 
    usage = 'usage: %prog [options] <TaskSim config file> <TaskSim results file> <Private L2 (1 private, 0 shared/coherent)> <L3 (0 no, 1 yes)>'
    results = Statistics()
    parser = OptionParser(usage=usage)
    parser.add_option('-o', '--out', type='string',
        action='store', dest='out', default='mcpat-out.xml',
        help='output file (input to McPAT)')
    (opts, args) = parser.parse_args()
    if len(args) != 4:
        parser.print_help()
        sys.exit(1)
    PRIVATEL2 = args[2]
    CACHE3 = args[3]
    _stats_load(results, args[0])
    _results_load(results, args[1])
    _template_load(results, TEMPLATE, TEMPLATE_DIR, opts.out)
    
if __name__ == '__main__':
    main()
     
