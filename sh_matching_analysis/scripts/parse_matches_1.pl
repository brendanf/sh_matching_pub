#!/usr/bin/perl
use strict;
use warnings;

# input data
my $run_id = $ARGV[0];
if ($run_id !~ m/^[0-9]{1,}$/) {
    print "Need correct run id - number!\n";
    exit;
}

my $user_dir = "userdir/$run_id";
my $matches_dir = $user_dir . "/matches";
my $duplicate_seqs_file = $user_dir . "/" . "source_" . $run_id . "_fastanames";
my $accno_seqs_file = $user_dir . "/" . "source_" . $run_id . "_names";

my %threshold_hash = ("97" => "3.0", "975" => "2.5", "98" => "2.0", "985" => "1.5", "99" => "1.0", "995" => "0.5", "100" => "<0.5");

# read in duplicate seqs
my %seq_duplicate_hash = ();
open (INFILE_DUPL, $duplicate_seqs_file);
while (<INFILE_DUPL>) {
    chomp $_;
    my @fields = split("\t", $_);
    if ($fields[0] ne $fields[1]) {
        $seq_duplicate_hash{$fields[0]} = $fields[1];
    }
}
close INFILE_DUPL;

# read in sequence metadata from csv file
my %seq_id_hash = ();
open (INFILE_ACCNOS, $accno_seqs_file);
while (<INFILE_ACCNOS>) {
    chomp $_;
    my @fields = split("\t", $_);
    my $seq_id = $fields[1];
    $seq_id =~ s/i//g;
    $seq_id_hash{$seq_id} = $fields[0];
}
close INFILE_ACCNOS;

# parse files for each threshold
my $new_sh_counter = 0;
my $new_singleton_counter = 0;

my @thresholds = ("97", "975", "98", "985", "99");
foreach my $threshold (@thresholds) {
    my $matches_file = $matches_dir . "/" . "matches_1_" . $threshold . ".txt";
    my $matches_outfile = $matches_dir . "/" . "matches_1_out_" . $threshold . ".csv";
    my $header = "seq_id_tmp\tseq_accno\tstatus (" . $threshold_hash{$threshold} . ")\tSH code (" . $threshold_hash{$threshold} . ")\tcompound_cl_code (" . $threshold_hash{$threshold} . ")\n";

    my $new_sh_counter_th = 0;
    my $new_sh_seq_counter_th = 0;
    my $new_singleton_counter_th = 0;
    my %new_sh_hash_th = ();

    # open matches file
    open (MATCHES, $matches_file);
    open (MATCHES_OUT, ">", $matches_outfile);

    # print header
    print MATCHES_OUT $header;

    while (<MATCHES>) {
        chomp $_;
        my @fields = split("\t", $_);
        my $seq_id = $fields[0];
        $seq_id =~ s/i//g;

        print MATCHES_OUT $seq_id . "\t" . $seq_id_hash{$seq_id} . "\t";

        my $duplicate_sh_code = "";
        my $duplicate_ucl_code = "";

        if ($fields[2] eq "new cluster") {
            $new_sh_seq_counter_th++;
            my $new_sh_code = "";
            if (!defined($new_sh_hash_th{$fields[4]})) {
                $new_sh_counter++;
                $new_sh_counter_th++;
                $new_sh_hash_th{$fields[4]} = $new_sh_counter;
                $new_sh_code = $new_sh_counter;
            } else {
                $new_sh_code = $new_sh_hash_th{$fields[4]};
            }
            print MATCHES_OUT "new_sh_in\tn" . $new_sh_code . "\t";
            $duplicate_sh_code = "n" . $new_sh_code;
        } elsif ($fields[2] eq "singleton") {
            $new_singleton_counter++;
            $new_singleton_counter_th++;
            print MATCHES_OUT "new_singleton_in\tns". $new_singleton_counter . "\t";
            $duplicate_sh_code = "ns" . $new_singleton_counter;
        }
        if (!defined($fields[3])) {
            print "Not defined - $seq_id\n";
            print MATCHES_OUT "\t";
        } else {
            print MATCHES_OUT $fields[3] . "\t";
            $duplicate_ucl_code = $fields[3];
        }
        print MATCHES_OUT "\n";
        # check duplicates
        if (defined($seq_duplicate_hash{$fields[0]})) {
            my @fields2 = split(",", $seq_duplicate_hash{$fields[0]});
            for (my $k=0; $k<scalar(@fields2); $k++) {
                if ($k > 0) {
                    my $dupl = $fields2[$k];
                    $dupl =~ s/i//g;
                    # print each duplicate in a separate row
                    print MATCHES_OUT $dupl . "\t" . $seq_id_hash{$dupl} . "\t";
                    print MATCHES_OUT "duplicate_of_" . $seq_id_hash{$seq_id} . "\t" . $duplicate_sh_code . "\t" . $duplicate_ucl_code . "\n";
                }
            }
        }
    }
    close MATCHES;
    close MATCHES_OUT;

    print "\nNo. of sequences in new SHs ($threshold): " . $new_sh_seq_counter_th . "\n";
    print "No. of new SHs ($threshold): " . $new_sh_counter_th . "\n";
    print "No. of new singleton SHs ($threshold): " . $new_singleton_counter_th . "\n";
}

print "\nTotal no. of new SHs: " . $new_sh_counter . "\n";
print "Total no. of new singleton SHs: " . $new_singleton_counter . "\n\n";

exit;
