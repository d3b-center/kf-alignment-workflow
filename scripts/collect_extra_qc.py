'''Calculate QC metrics that fastqc doesn't explicitly provide.'''
import sys
import os
import argparse
import zipfile

def parse_args(args):
    '''Get file argument.'''
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--file",
        help="Fastqc raw data file.",
        required=True
        )
    args = parser.parse_args()
    file = args.file
    if not os.path.isfile(file):
        raise ValueError(file + " is not a file or does not exist.")
    return file

def unzip_fastqc_dir(zipped_file):
    '''Unzip fastqc raw directory and return data file.'''
    src_dir = os.path.dirname(zipped_file)
    unzip_dir = os.path.basename(zipped_file).split('.')[0]
    with zipfile.ZipFile(zipped_file, 'r') as zip_ref:
        zip_ref.extractall(src_dir)
    file = unzip_dir + "/fastqc_data.txt"
    return file

def main(args):
    '''Main, take args, run script.'''

    #parse args
    zipped_file = parse_args(args)
    sample_name = os.path.basename(zipped_file)
    sample_name = os.path.splitext(sample_name)[0]
    #remove '_fastqc' to get original sample name
    sample_name = sample_name.replace('_fastqc', '')

    #unzip file
    file = unzip_fastqc_dir(zipped_file)

    process = 0 #flag to determine if we're in the right secion
    total_base = 1.0
    base_q30 = 0.0
    base_q20 = 0.0

    #lines where per base quality section starts and ends
    per_base_start = '>>Per sequence quality scores'
    per_base_stop = '>>END_MODULE'
    with open(file) as f:
        for line in f:
            #if in the correct section, start processing line
            if per_base_start in line:
                #turn processing on
                process = 1
            elif per_base_stop in line and process == 1:
                #stop processing at section end
                process = 0
            elif process == 1:
                #process the line
                line = line.rstrip()
                if 'Quality' not in line:
                    quality, count = line.split('\t')
                    quality = float(quality)
                    count = float(count)
                    total_base += count
                    if quality >= 30.0:
                        base_q30 += count
                    if quality >= 20.0:
                        base_q20 += count

    #return output
    perc_20 = base_q20 / total_base
    perc_30 = base_q30 / total_base
    print("sample_name,percent Q20, percent Q30")
    print("%s,%s,%s" % (sample_name, perc_20, perc_30))

if __name__ == "__main__":
    # execute only if run as a script
    main(sys.argv)
