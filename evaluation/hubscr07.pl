#!/usr/bin/perl -w

use strict;

### Revision History
# Version 0.1, Release Sep 19, 1997
#    - initial release
# Version 0.2, Release Oct 29, 1997
#    - added support for sc_stats
#    - modified the csrfilt call for German and Spanish to is use the -e option
#      which tells it to upcase extended ASCII as well as 7-bit ASCII.
# Version 0.3, 
#    - Modified the filter proceedure to ALWAYS tell the user if it skipped the 
#      filtering stage.
# Version 0.4, Release April 6, 1998
#    - added access to the RESULTS Server
#    - added -M and -w options
# Version 0.5, Released March 5, 2000
#    - Modifed to require updated tranfilt package
# Version 0.6, Not released
#    - Modified to accept Extended CTMs for the RT evaluation series, selected
#      via the -C option.
#    - Added a new hub scoring type rt-stt
#    - Removed access to the RESULTS server
#    - Changed local variables to my variables
# Version 0.7
#    - Added sort command to sort ctm file
#
my $Version = "0.7"; 
my $Usage="hubscr07.pl [ -R -v -L LEX ] [ -M LM | -w WWL ] -g glm -l LANGOPT -h HUBOPT -r ref hyp1 hyp2 ...\n".
"Version: $Version\n".
"Desc: Score a Hub-4E/NE or Hub-5E/NE evaluation using the established\n".
"      guidelines.  There are a set of language dependent options that this\n".
"      script requires, they are listed below with their dependencies.\n".
"      If more than one hyp is present, the set of hyps are viewed as an\n".
"      'ensemble' of result that can be statistically compared with sc_stats.\n".
"      The output reports are written with a root filename specified by '-n'\n".
"      and optionally described with the '-e' flag.\n".
"General Options:\n".
"      -g glm     ->  'glm' specifies the filename of the Global Mapping Rules\n".
"      -v         ->  Verbosely tell the user what is being executed\n". 
"      -h [ hub4 | hub5 | rt-stt ]\n".
"                 ->  Use scoring rules for hub4 or hub5.  Currently there is no\n".
"                     difference in scoring\n".
"      -l [ arabic | english | german | mandarin | spanish ]\n".
"                 ->  Set the input language.\n".
"      -L LDC_Lex ->  Filename of an LDC Lexicon.  The option is required only to\n".
"                     score a German or Arabic test.\n".
"      -M SLM_lm  ->  Use the CMU-Cambridge SLM V2.0 binary language model 'LM'\n".
"                     to perform Weighted-Word Scoring.  May not be used with -w\n".
"      -w WWL     ->  Use the Word-Weight List File to perform Weighted-Word\n".
"                     scoring.  May not be used with -M\n".
"Other Options:\n".
"      -n str     ->  Root filename to write the ensemble reports to.  Default\n".
"                     is 'Ensemble'\n".
"      -e 'desc'  ->  Use the description 'desc' as a sub-header in all reports.\n".
"\n";


################################################################
#############     Set all Global variables         #############
    my $Vb = 0;
    my $Lang = "Undeterm";
    my $Hub = "Undeterm";
    my $Ref = "Undeterm";
    my @Hyps = ();
    my @Hyps_iname = ();
    my @Hyps_oname = ();
    ### Installation directory for the SCTK package.  If the package's
    ### executables are accessible via your path, this variable may remain 
    ### empty.
    my $SCTK = "/data/data1/RT-03/DryRun/software/sctk-1.2c";
    my $SCLITE = "";
    my $SC_STATS = "";
    ### Installation directory for the tranfilt package.   If the package's
    ### executables are accessible via your path, this variable may remain 
    ### empty.
    my $TRANFILT="/data/data1/RT-03/DryRun/software/tranfilt-1.12";
    my $CSRFILT="";
    my $DEF_ART="";
    my $GLM = "";
    my $ACOMP = "";
    my $LDCLEX = "";
    ### Defaults for SC_stats
    my $EnsembleRoot = "";
    my $EnsembleDesc = "";
    ###
    my $SLM_LM = "";
    my $WWL = "";
#######         End of Globals         #########
################################################

################################################
#######          MAIN PROGRAM          #########
&ProcessCommandLine();

my($h); 
&VerifyResources();

&FilterFile($Ref, $Ref.".filt", $Lang, "stm");
for ($h=0; $h<=$#Hyps; $h++){
    &FilterFile($Hyps[$h], $Hyps_oname[$h], $Lang, "ctm");
    &RunScoring($Ref,$Hyps[$h],$Hyps_iname[$h],$Hyps_oname[$h],$Lang);
}
    
&RunStatisticalTests(@Hyps_oname) if ($#Hyps > 0);

exit 0;

#######          END OF MAIN           #########
################################################


################################################################
################ Get the command line arguments ################
sub ProcessCommandLine{
    use Getopt::Std;
    #&Getopts('l:h:r:vg:L:n:e:RM:w:');
    getopts('vRl:h:r:g:L:n:e:M:w:');

    if (defined($main::opt_l)) {  $Lang = $main::opt_l; $Lang =~ tr/A-Z/a-z/; }
    if (defined($main::opt_h)) {  $Hub = $main::opt_h; $Hub =~ tr/A-Z/a-z/; }
    if (defined($main::opt_r)) {  $Ref = $main::opt_r; }
    if (defined($main::opt_v)) {  $Vb = 1; $main::opt_v = 1; }
    if (defined($main::opt_L)) {  $LDCLEX = $main::opt_L; }
    if (defined($main::opt_n)) {  $EnsembleRoot = $main::opt_n; }
    if (defined($main::opt_e)) {  $EnsembleDesc = $main::opt_e; }
    if (defined($main::opt_M)) {  $SLM_LM = $main::opt_M; }
    if (defined($main::opt_w)) {  $WWL = $main::opt_w; }
    if (defined($main::opt_g)) {  
  $GLM = $main::opt_g; 
  die("$Usage\nError: Unable to stat GLM file '$GLM'") if (! -f $GLM);
    } else {
  die("$Usage\nError: GLM file required via -g option");
    }

    #### Language checks/Verification
    die("$Usage\nError: Language defintion required via -l") if ($Lang eq "Undeterm"); 
    die("$Usage\nError: Undefined language '$Lang'") 
  if ($Lang !~ /^(english|german|spanish|mandarin|arabic)$/);

    #### Hub Check/Verification
    die("$Usage\nError: Hub defintion required via -h") if ($Hub eq "Undeterm"); 
    die("$Usage\nError: Undefined Hub '$Hub'") if ($Hub !~ /^(hub4|hub5|rt-stt)$/);

    #### Reference File Check/Verification
    die("$Usage\nError: Reference file defintion required via -r") if ($Ref eq "Undeterm"); 
    die("$Usage\nError: Unable to access reference file '$Ref'\n") if (! -f $Ref);

    #### extract the hypothesis files
    die("$Usage\nError: Hypothesis files required") if ($#ARGV < 0);
    my @Hyps_DEFS = @ARGV;
    my $hyp;
    foreach $hyp(@Hyps_DEFS){
  print "$hyp\n";
  my(@Arr) = split(/\\#/,$hyp);
        if ($#Arr < 1) { $Arr[1] = $Arr[0]; } elsif ($Arr[1] =~ /^$/) { $Arr[1] = $Arr[0]; }
        if ($#Arr < 2) { $Arr[2] = $Arr[0]; } elsif ($Arr[2] =~ /^$/) { $Arr[2] = $Arr[0]; }
  push(@Hyps,$Arr[0]);
        push(@Hyps_iname,$Arr[1]);
        push(@Hyps_oname,$Arr[2].".filt");
    }
    foreach $hyp(@Hyps){
  die("$Usage\nError: Unable to access hypothesis file '$hyp'\n") if (! -f $hyp);
    }

    print STDERR "Warning: LDC lexicon option '-L $LDCLEX' ignored!!!!\n"
  if (($Lang ne "german" && ($Lang ne "arabic")) && $LDCLEX ne "");

    die("$Usage\nError: Unable to access LDC Lexicon file '$LDCLEX'\n") 
  if ((($Lang eq "german") || ($Lang eq "arabic")) && (! -f $LDCLEX));

    #### Check the LM and WWL files
    die("$Usage\nError: Unable to use both -M and -w\n") 
  if (defined($main::opt_M) && defined($main::opt_w));
    die("$Usage\nError: SLM language model '$main::opt_M' not found\n") 
  if (defined($main::opt_M) && (! -f $main::opt_M));
    die("$Usage\nError: WWL file '$main::opt_w' not found\n") 
  if (defined($main::opt_w) && (! -f $main::opt_w));
}

################################################################
###########  Make sure sclite, tranfilt, and other  ############
###########  resources are available.               ############
sub get_version{
    my($exe, $name) = @_;
    my($ver) = "foo";

    open(IN,"$exe 2>&1 |") ||
  die("Error: unable to exec $name with the command '$exe'");
    while (<IN>){
  if ($_ =~ /Version: (\d+\.\d+)[a-z]*/){
      $ver = $1;
  }
    }
    close(IN);
    die "Error: unable to exec $name with the command '$exe'"
  if ($ver eq "foo");
    $ver;
}

sub VerifyResources{
    my($ver);

    #### 
    #### look for sctk
    if ($SCTK ne ""){
  die("$Usage\nError: variable \$SCTK ($SCTK) does not defined a valid\n".
      "       directory.  The package ls available from the URL\n".
      "       http://www.nist.gov/speech/software.htm") if (! -d $SCTK);
  $SCLITE = "$SCTK/src/sclite";
  $SC_STATS = "$SCTK/src/sc_stats";
    } else {
  if ($Vb){
      print("Advisement: using SCTK executables via \$PATH environment variable\n");
  }
  $SCLITE = "sclite";
  $SC_STATS = "sc_stats";
    }
    ### Check the version of sclite
    $ver = "";
    open(IN,"$SCLITE 2>&1 |") ||
  die("Error: unable to exec sclite with the command '$SCLITE'");
    while (<IN>){
  if ($_ =~ /sclite Version: (\d+\.\d+)[a-z]*,/){
      $ver = $1;
  }
    }
    close(IN);
    die ("SCLITE executed by the command '$SCLITE' is too old. \n".
   "       Version 2.0 or better is needed.  This package ls available\n".
   "       from the URL http://www.nist.gov/speech/software.htm") if ($ver < 2.0);

    ### Check the version of sclite
    $ver = "";
    open(IN,"$SC_STATS 2>&1 |") ||
  die("Error: unable to exec sc_stats with the command '$SC_STATS'");
    while (<IN>){
  if ($_ =~ /sc_stats Version: (\d+\.\d+)[a-z]*,/){
      $ver = $1;
  }
    }
    close(IN);
    die ("SC_STATS executed by the command '$SC_STATS' is too old. \n".
   "       Version 1.1 or better is needed.  This package ls available\n".
   "       from the URL http://www.nist.gov/speech/software.htm") if ($ver < 1.1);

    ##### 
    #####  Look for tranfilt
    if ($TRANFILT ne ""){
  die("$Usage\nError: variable \$TRANFILT does not defined a valid\n".
      "       directory.  This package ls available from the URL\n".
      "       http1://www.nist.gov/speech/software.htm") if (! -d $TRANFILT);
  $CSRFILT = "$TRANFILT/csrfilt.sh";
  $DEF_ART = "$TRANFILT/def_art.pl";
  $ACOMP =   "$TRANFILT/acomp.pl";
    } else {
  if ($Vb){
      print("Advisement: using TRANFILT executables via ".
      "\$PATH environment variable\n");
  }
  $CSRFILT = "csrfilt.sh";
  $DEF_ART = "def_art.pl";
  $ACOMP =   "acomp.pl";
    }
    #### Check for CSRFILT
    $ver = &get_version($CSRFILT,"csrfilt.sh");
    die ("CSRFILT executed by the command '$CSRFILT' is too old. \n".
   "       Version 1.10 or better is needed.  This package ls available\n".
   "       from the URL http://www.nist.gov/speech/software.htm") if ($ver < 1.10 || $ver >= 1.2);

    $ver = &get_version($DEF_ART,"def_art.pl");
    die ("def_art.pl executed by the command '$DEF_ART' is too old. \n".
   "       Version 1.0 or better is needed.  This package ls available\n".
   "       from the URL http://www.nist.gov/speech/software.htm") if ($ver < 1.0);

    $ver = &get_version($ACOMP,"acomp.sh");
    die ("acomp.pl executed by the command '$ACOMP' is too old. \n".
   "       Version 1.0 or better is needed.  This package ls available\n".
   "       from the URL http://www.nist.gov/speech/software.htm") if ($ver < 1.0);


}

sub FilterFile{
    my($file, $outfile, $lang, $format) = @_;
    my($rtn);
    my($csrfilt_com);
    my($def_art_com);
    my($acomp_com);
    my($sort_com);
    my($com);

    print "Filtering $lang file '$file', $format format\n";
    if (! -f $outfile){
  my $rtFilt = "cat";
  if ($Hub eq "rt-stt" && $format eq "ctm"){
      $rtFilt = "perl -nae 'if (\$_ =~ /^;;/ || \$#F < 6) {print} else {s/^\\s+//; if (\$F[6] eq 'lex') { splice(\@F, 6, 10); print join(\" \" ,\@F).\"\\n\" }}' "
  }
  if ($format eq "ctm"){
      $sort_com = "sort +0 -1 +1 -2 +2nb -3";
  } elsif ($format eq "stm") {
      # should be sorted already
      $sort_com = "cat";
  }
  if ($Lang =~ /^(arabic)$/){ 
      $csrfilt_com = "$CSRFILT -s -i $format -dh $GLM";
      $def_art_com = "$DEF_ART -s $LDCLEX -i $format - -";
      $com = "$sort_com $file | $rtFilt | $def_art_com | $csrfilt_com > $outfile";
  } elsif ($Lang =~ /^(mandarin)$/){ 
      $csrfilt_com = "$CSRFILT -i $format -dh $GLM";

      $com = "cat $file | $rtFilt | $csrfilt_com > $outfile";
  } elsif ($Lang =~ /^(spanish)$/){ 
      $csrfilt_com = "$CSRFILT -e -i $format -dh $GLM";

      $com = "$sort_com $file | $rtFilt | $csrfilt_com > $outfile";
  } elsif ($Lang =~ /^(german)$/){ 
      $csrfilt_com = "$CSRFILT -e -i $format -dh $GLM";
      $acomp_com =   "$ACOMP -f -m 2 -l $LDCLEX -i $format - -";

      $com = "$sort_com $file | $rtFilt | $csrfilt_com | $acomp_com > $outfile";
  } elsif ($Lang =~ /^(english)$/){ 
      $csrfilt_com = "$CSRFILT -i $format -dh $GLM";
      $com = "$sort_com $file | $rtFilt | $csrfilt_com > $outfile";
  } else {
      die "Undefined language: '$lang'";
  }

#     $com = "cat $file | $rtFilt > $outfile";
  print "   Exec: $com\n" if ($Vb);
  $rtn = system $com;
  if ($rtn != 0) {
      system("rm -f $outfile");
      die("Error: Unable to filter file: $file with command:\n   $com\n");
  }
    } else {
  print "   ....Already filtered.  Delete $outfile to re-filter\n"
    }
}

sub RunScoring{
    my($ref, $hyp, $hyp_iname, $hyp_oname, $lang) = @_;
    my($reff) = ($ref.".filt");
    my($rtn);
    my($outname);

    ($outname = "-n $hyp_oname") =~ s:^-n (\S+)/([^/]+)$:-O $1 -n $2:;
    print "Scoring $lang Hyp '$hyp_oname' against ref '$reff'\n";

    my $command = "$SCLITE -r $reff stm -h $hyp_oname ctm $hyp_iname -F -D -o sum rsum sgml lur dtl pra -C det sbhist hist $outname";
    if ($Lang =~ /^(mandarin)$/){ 
  $command .= " -c NOASCII DH -e gb";
    }
    if ($Lang =~ /^(arabic)$/){ 
  $command .= " -s";
    }
    if ($Lang =~ /^(spanish)$/){ 
  ;
    }
    if ($SLM_LM !~ /^$/ || $WWL !~ /^$/){ 
  $command .= " -L $SLM_LM" if ($SLM_LM !~ /^$/);
  $command .= " -w $WWL" if ($WWL !~ /^$/);
  $command .= " -o wws";
    }

    print "   Exec: $command\n" if ($Vb);
    $rtn = system($command);
    die("Error: SCLITE execution failed\n      Command: $command") if ($rtn != 0);
}

sub RunStatisticalTests{
    my(@Hy) = @_;
    my($hyp);
    my($sgml);
    my($command) = "";
    my($rtn);

    print "Running Statistical Comparison Tests\n";
    
    $command = "cat";
    ## verify the sgml files were made, and add to the cat list;
    print "    Checking for sclite's sgml files\n" if ($Vb);
    foreach $hyp(@Hy){
  $sgml = $hyp.".sgml";
  die "Error: Unable to local sgml file '$sgml'" if (! -f $sgml);
  $command .= " $sgml";
    }
    $command .= " | $SC_STATS -p -r sum rsum es res lur -t std4 -u -g grange2 det";
    $command .= " -n $EnsembleRoot" if ($EnsembleRoot ne "");
    $command .= " -e \"$EnsembleDesc\"" if ($EnsembleDesc ne "");

    print "    Exec: $command\n" if ($Vb);
    $rtn = system($command);
    die("Error: SC_STATS execution failed\n      Command: $command") if ($rtn != 0);
}


