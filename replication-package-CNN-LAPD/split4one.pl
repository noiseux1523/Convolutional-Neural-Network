#!/opt/local/bin/perl

use strict;

# getting a file assume is csv with "!" and the to last  filds are information but the second si  0/1 define if positiive or negative example
# create a set of training/test pairs to trick CNN eval ...

open (FH, $ARGV[0] ) or die" Unable to read file $ARGV[0] \n";
my @lines = <FH>;
close(FH);
chop(@lines);

#
# I need this to easy compatibility with parallel daemon running
#
my $tag="unkn";

if ( defined ($ARGV[1])){
  $tag=$ARGV[1];
}

my $where=$ARGV[0];
$where =~ s/\.csv//g;
$where=$where . "-training";
mkdir $where;
shift @lines;  # skip first line the header

# create and open train and test file lists

my $train_set=$where."/"."train.txt";
open (FHT, ">$train_set") or die "Unable to create $train_set\n";


my $test_set=$where."/"."test.txt";
open (FHTT, ">$test_set") or die "Unable to create $test_set\n";


for (my $p=0;$p<=$#lines;$p++){

  my @array=doSplice($p, @lines);
  my $test = $lines[$p];
  # train file names
  
  my $nname=$where."/".$p . "-train-$tag-no.neg";
  my $pname=$where."/".$p . "-train-$tag-yes.pos";
  print FHT "data/".$nname.":data/".$pname,"\n"; # assume multiple training sets are under data root directory

  open (FH, ">$nname") or die "Unable to create $nname\n";
  my @narray = doSubSet(@array, 0);
  print FH join ("\n",@narray),"\n";
  close(FH);

  open (FH, ">$pname") or die "Unable to create $pname\n";
  my @parray = doSubSet(@array, 1);
  print FH join ("\n",@parray),"\n";
  close(FH);

  #test file names
  $nname=$where."/".$p ."-test-$tag-no.neg";
  $pname=$where."/".$p ."-test-$tag-yes.pos";
  print FHTT "data/".$nname.":data/".$pname,"\n";

  # store atual test data

  my @f = split('!', $test);
  open (FHN, ">$nname") or die "Unable to create $nname\n";
  open (FHP, ">$pname") or die "Unable to create $pname\n";

  # store test info for later analyses
  
  my $iname=$where."/".$p ."-test-$tag-info.txt"; # info name
  open (FHI, ">$iname") or die "Unable to create $iname\n";
  print FHI $test,"\n";
  close(FHI);
  
  if ( $f[1]  eq "0" ) {
    close(FHP); # negative data
    print FHN $f[0],"\n";
    close(FHN);
    
  }elsif ( $f[1]  eq "1" ) {
    close(FHN); # positive data
    print FHP $f[0],"\n";
    close(FHP);
  }else{
    die "Neither  zero or one at $p in >>$test<<\n";
  }
}

close(FHT);
close(FHTT);

exit(0);

sub doSplice{
  my $n=shift;
  my @s=(@_);

  my @ns = splice @s, $n, 1 ;

  return (@s);
}


sub doSubSet{
  my @s=(@_);
  my $what=pop @s;
  my @array = ();
  
  foreach my $l (@s){
    #
    # notice the hugly hard coding ...!!!
    #
    my @f=split("!",$l);
    my $t=$f[0];
    my $is=$f[1];
    if ( $is eq $what){
      push @array, $t;
    }
  }

  return (@array);
}
