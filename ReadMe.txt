ReadMe for Audio Transcriber/Recorder

version 0.9.3
Fixes in this version include some Timer_record.pm problems.

Install the Audio Transcriber/Recorder by unpacking into its own directory.
tar -xvf transcriber.tar

If your sox program is older than sox-12.17.1 (or if the trim funtionality of recorder.pl does not seen to work) install the sox-12.17.1-t.tar that is in the /transcriber directory. First remove your sox program.
From within the /transcriber directory:
gunzip ./sox-12.17.1-t.tar.gz
tar -xvf ./sox-12.17.1-t.tar
cd ./sox-12.17.1-t
./configure
make
make install

Run Audio Transcriber/Recorder by running, from an xterm, recorder.pl from the directory where transcriber was unpacked. bash# /path-to-transcriber/recorder.pl

Go to cpan and get the Tk800.xxx and Tk-Month modules.
Install the perl TK800.xxx and Tk-Month modules as follows from in the directory where you downloaded the modules to:
gunzip Tk800.xxx.tar.gz   #where xxx is the minor nuber
tar -xvf ./Tk800.xxx.tar  #substitute Tk-Month for the Tk-Month module
cd ./Tk800.xxx	          #you may need to be root to install perl modules
perl Makefile.PL
make
make test
make install  


Questions or comments? massey@stlouis-shopper.com
