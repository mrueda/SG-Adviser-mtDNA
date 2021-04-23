package HTML;

use strict;
use warnings;
use autodie;
use JSON::XS;                     # cpan JSON JSON::XS
use Fcntl qw(:flock SEEK_END);    # import LOCK_* and SEEK_END constants

#use Data::Dumper;

=head1 NAME

  MTDNA::HTML - Package for HTML generation

=head1 SYNOPSIS

  use MTDNA::HTML

=head1 DESCRIPTION


=head1 AUTHOR

Written by Manuel Rueda, PhD

=cut

=head1 METHODS

=cut

sub new {
    my ( $class, $args_sub ) = @_;
    my $self = { job_id => $args_sub->{job_id} };
    bless $self, $class;
    return $self;
}

sub status_data_page {
    my $str = '';
    $str .= html_header( '', 'status' );
    $str .= html_body_status('status');
    $str .= html_footer();
    return $str;
}

sub status_wellderly_page {
    my $str = '';
    $str .= html_header( '', 'wellderly' );
    $str .= html_body_status('wellderly');
    $str .= html_footer();
    return $str;
}

sub results_page {
    my ($self) = @_;
    my $job_id = $self->{job_id};
    my $str    = '';
    $str .= html_header( $job_id, 'results' );
    $str .= html_body_results($job_id);
    $str .= html_footer();
    return $str;
}

=head2 get_dataTables

    About   : 
    Usage   : None             
    Args    : 

=cut

sub get_dataTables {

    my $job_id = shift;    # 'status' and 'wellderly' do not get job_id
    my $page   = shift;
    my $json   = '';
    my $str    = '';
    my $data_dir = $page eq 'wellderly' ? 'wellderly' : 'data';

    # In results page, we have no way of knowing if we come from 'status' or 'wellderly'
    # yet we need to set data_loc
    # Ad hoc solution below
    # wLP6005830_DNA
    # wLP6005831_DNA
    # wLP6005832_DNA
    # wLP6005833_DNA
    my $regex = qr/^wLP600583[0-3]_DNA_/;
    if ( $page eq 'results' && $job_id ) {
        $data_dir = 'wellderly'
          if $job_id =~ m/$regex/o; # Almost impossible to find that regex in external samples
    }
    my $data_loc = $page eq 'results' ? "../../$data_dir/" : "../$data_dir/";

    if ( $page eq 'results' ) {
        $json = $data_loc . $job_id . '/mit.json';
        $str .= << "EOF";

  <script type="text/javascript" language="javascript" class="init">

   \$(document).ready(function() {
    \$('#table-results-mit').dataTable( {
        "ajax": "$json",
        "bDeferRender": true,
         stateSave: true,
        "language": {
         "sSearch": '<span class="icon-search" aria-hidden="true"></span>',
         "lengthMenu": "Show _MENU_ variants",
         "sInfo": "Showing _START_ to _END_ of _TOTAL_ variants",
          "sInfoFiltered": " (filtered from _MAX_ variants)"
       },
        "order": [[ 8, "desc" ]],
        search: {
          "regex": true
         },
       aoColumnDefs: [
          { visible: false, targets: [ 9, 11, 18, 13, 14, 20, 21 ] }
       ], 
       dom: 'CRT<"clear">lfrtip',
       colVis: {
            showAll: "Show all",
            showNone: "Show none"
        },
          tableTools: {
            aButtons: [ { "sExtends": "print" , "sButtonText": '<span class="icon-print" aria-hidden="true"></span>' } ]
        } 
     } );
   } );

   </script>

EOF
    }
    else {

        $json = $data_loc . 'status.json';
        $str .= << "EOF";

  <script type="text/javascript" language="javascript" class="init">

   \$(document).ready(function() {
    \$('#table-status-mit').dataTable( {
        "ajax": "$json",
        "search": {
          "regex": true
         },
        dom: 'Rlfrtip',
        stateSave: true,
        "bDeferRender": true,
         "language": {
         "sSearch": '<span class="icon-search" aria-hidden="true"></span>',
         "lengthMenu": "Show _MENU_ jobs",
         "sInfo": "Showing _START_ to _END_ of _TOTAL_ jobs",
          "sInfoFiltered": " (filtered from _MAX_ jobs)"
       },
        "order": [[ 1, "desc" ]],
     } );
   } );

   </script>

EOF
    }

    return $str;

}

=head2 html_header

    About   : 
    Usage   : None             
    Args    : 

=cut

sub html_header {

    my $job_id           = shift;
    my $page             = shift;
    my $ucfirst_page     = ucfirst($page);
    my $active_status    = $page eq 'status' ? 'active' : '';
    my $active_wellderly = $page eq 'wellderly' ? 'active' : '';
    my $reload =
      $page eq 'status' ? '<meta http-equiv="refresh" content="300">' : '';
    my $dataTables = get_dataTables( $job_id, $page );
    my $cd         = $page eq 'results' ? '../..' : '..';
    my $str        = << "EOF";

<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>SG-ADVISER mtDNA $ucfirst_page Page</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="SG-ADVISER mtDNA: mitochondrial DNA annotation">
    <meta name="author" content="Manuel Rueda">
    $reload
    
    <!-- Le styles -->
    <link rel="icon" href="$cd/img/favicon.ico" type="image/x-icon" />
    <link rel="stylesheet" type="text/css" href="$cd/css/bootstrap.css" rel="stylesheet">
    <link rel="stylesheet" type="text/css" href="$cd/css/bootstrap-responsive.css" rel="stylesheet">
    <link rel="stylesheet" type="text/css" href="$cd/css/main.css" rel="stylesheet">
    <link rel="stylesheet" type="text/css" href="$cd/jsD/media/css/jquery.dataTables.css">
    <link rel="stylesheet" type="text/css" href="$cd/jsD/media/css/dataTables.colReorder.css">
    <link rel="stylesheet" type="text/css" href="$cd/jsD/media/css/dataTables.colVis.css">
    <link rel="stylesheet" type="text/css" href="$cd/jsD/media/css/dataTables.tableTools.css">
   
    <script src="$cd/js/jquery.min.js"></script>
    <script src="$cd/js/bootstrap.min.js"></script>
    <script src="$cd/js/main.js"></script>
    <script src="$cd/jsD/media/js/jquery.dataTables.min.js"></script>
    <script src="$cd/jsD/media/js/dataTables.colReorder.js"></script>
    <script src="$cd/jsD/media/js/dataTables.colVis.js"></script>
    <script src="$cd/jsD/media/js/dataTables.tableTools.js"></script>
    <script src="$cd/js/jqBootstrapValidation.js"></script>

   $dataTables
  </head>
  <body class="dt-example">

    <!-- NAVBAR
    ================================================== -->
    <div class="navbar navbar-inverse navbar-fixed-top">
            <div class="navbar-inner">
                <div class="container">
                    <a class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                    </a>
                    <a class="brand" href="$cd">SG-ADVISER mtDNA</a>
                    <div class="nav-collapse collapse">
                        <ul class="nav">
                            <li><a href="$cd"><i class="icon-home icon-white"></i>Home</a></li>
                             <li class="dropdown">
                                <a href="#" class="dropdown-toggle" data-toggle="dropdown">Run <b class="caret"></b></a>
                                <ul class="dropdown-menu">
                                    <li class="nav-header">Server</li>
                                    <li><a href="$cd/#start-using-it"><span class="icon-forward"></span> Start using it &raquo;</a></li>
                                    <li class="divider"></li>
                                    <li class="nav-header">Test-Job</li>
                                    <li><a href="$cd/results/job/mtDNA_Test_Job"><span class="icon-eye-open"></span> Explore it &raquo;</a></li>
                                </ul>
                            </li>
                            <li class="$active_status"><a href="$cd/results/status">Status</a></li>
                            <li class="$active_wellderly"><a href="$cd/results/wellderly">Wellderly</a></li>
                            <li class="dropdown">
                                <a href="#" class="dropdown-toggle" data-toggle="dropdown">Help <b class="caret"></b></a>
                                <ul class="dropdown-menu">
                                    <li class="nav-header">Help</li>
                                    <li><a href="$cd/help.html"><span class="icon-question-sign"></span> Help Page</a>
                                    <li class="divider"></li>
                                    <li class="nav-header">FAQs</li>
                                    <li><a href="$cd/faq.html"><span class="icon-question-sign"></span> FAQs Page</a></a></li>
                                </ul>
                            </li>
                            <li class="dropdown">
                                <a href="#" class="dropdown-toggle" data-toggle="dropdown">Links <b class="caret"></b></a>
                                <ul class="dropdown-menu">
                                    <li class="nav-header">Contact</li>
                                    <li><a href="mailto:mrueda\@scripps.edu"><span class="icon-envelope"></span> Author</a></li>
                                    <li class="divider"></li>
                                    <li class="nav-header">Corporate Info</li>
                                    <li><a href="http://www.scripps.edu"><span class="icon-home"></span> TSRI</a></li>
                                </ul>
                            </li>
                        </ul>
                    </div><!--/.nav-collapse -->
                </div>
            </div>
        </div>

EOF

    return $str;

}

=head2 html_body_status

    About   : 
    Usage   : None             
    Args    : 

=cut

sub html_body_status {

    my $page = shift;
    my (
        $total_job,     $total_sample, $total_finished,
        $total_running, $total_queued, $total_failed
    ) = read_sqs($page);

    my $str = << "EOF";
     <link href="//maxcdn.bootstrapcdn.com/font-awesome/4.2.0/css/font-awesome.min.css" rel="stylesheet">

     <div class="container">

     <button onClick="location.reload(true)" class="btn btn-inverse pull-right"><i class="icon-white icon-refresh"></i> Refresh</button>

     <h2>Status &#9658 $total_job jobs &#9658 $total_sample samples</h2>

    <div class="row-fluid pagination-centered">
	<div class="span3 alert alert-success">
		<h4>Finished</h4>
		<h4>$total_finished</h4>
	</div>
	
	<div class="span3 alert alert-info">
		<h4>Running</h4>
		<h4>$total_running</h4>
	</div>
	
	<div class="span3 alert alert-warning">
		<h4>Queued</h4>
		<h4>$total_queued</h4>
	</div>
	
	<div class="span3 alert alert-danger">
		<h4>Failed</h4>
		<h4>$total_failed</h4>
	</div>
	
      </div>
									
      <hr />

      <div>

      <div id="myTabContent" class="tab-content">
      <!-- TABLE -->
      <div class="tab-pane fade in active" id="tab-panel-mit">
      <!-- TABLE -->
      <table id="table-status-mit" class="display table table-hover table-condensed">
        <thead>
            <tr>
             <th>Job ID &#160;&#160;&#160;</th>
             <th>Queue ID</th>
             <th>Samples</th>
             <th>SAM/BAM files</th>
             <th>Date</th>
             <th>Status</th>
            </tr>
        </thead>
    </table>

      </div>
      </div>
      </div>

EOF

    return $str;
}

=head2 html_body_results

    About   : 
    Usage   : None             
    Args    : 

=cut

sub html_body_results {

    my $job_id = shift;

    # Ad hoc to get wellderly folder
    my $regex = qr/^wLP600583[0-3]_DNA_/;
    my $data_dir =
      $job_id =~ m/$regex/o
      ? 'wellderly'
      : 'data';    # Almost impossible to find that regex in external samples
    my $data_loc = "../../$data_dir/";

    my $report = $data_loc . $job_id . '/mit_prioritized_variants.txt';
    my $vcf    = $data_loc . $job_id . '/VCF_file.vcf';
    my $info   = $data_loc . $job_id . '/info.txt';
    my $haplo  = $data_loc . $job_id . '/mt_classification_best_results.csv';

    my $str = << "EOF";

     <div class="container">

     <a class="btn pull-right" href="$vcf"><i class="icon-download"></i> VCF</a>
     <a class="btn pull-right" href="$haplo"><i class="icon-download"></i> HAPLOg</a>
     <a class="btn pull-right" href="$report"><i class="icon-download"></i> REPORT</a>
     <a class="btn pull-right" href="$info"><i class="icon-download"></i> INFO</a>

     <h2>SG-ADVISER mtDNA Results</h2>
     <h3>Job ID &#9658 $job_id</h3>

      <div>

      <div id="myTabContent" class="tab-content">
      <!-- TABLE -->
      <div class="tab-pane fade in active" id="tab-panel-mit">
      <!-- TABLE -->
      <table id="table-results-mit" class="display table table-hover table-condensed">
        <thead>
            <tr>
             <th>Sample&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;</th>
             <th>Locus&#160;&#160;&#160;&#160;&#160;</th>
             <th>Variant_Allele</th>
             <th>Ref</th>
             <th>Alt</th>
             <th>Aa_Change</th>
             <th>GT</th>
             <th>Depth</th>
             <th>Heterop_Frac</th>
             <th>tRNA_Annotation</th>
             <th>Disease_Score</th>
             <th>RNA_predictions</th>
             <th>Mitomap_Associated_Disease(s)</th>
             <th>Mitomap_Homoplasmy</th>
             <th>Mitomap_Heteroplasmy</th>
             <th>ClinVar</th>
             <th>OMIM_link</th>
             <th>dbSNP_ID</th>
             <th>Mamit-tRNA_link</th>
             <th>AC/AN_1000G</th>
             <th>1000G_Homoplasmy</th>
             <th>1000G_Heteroplasmy</th>
            </tr>
        </thead>
    </table>

      </div>
      </div>
      </div>

EOF

    return $str;
}

=head2 html_footer

    About   : 
    Usage   : None             
    Args    : 

=cut

sub html_footer {

    my $str = << "EOF";

      <br /><p class="pagination-centered">SCRIPPS GENOME ADVISER MT-DNA ANNOTATION</p> 
      <hr>
      <!-- FOOTER -->
      <footer>
                    <p>&copy; 2017 The Scripps Research Institute | U.S.A.</p>

      </footer>

    </div><!-- /.container -->

  </body>
</html>

EOF
    return $str;
}

=head2 google_analytics

    About   : 
    Usage   : None             
    Args    : 

=cut

sub google_analytics {
    my $str = " 
<!-- Google Analytics: -->
<script>
  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

  ga('create', 'UA-71888980-1', 'auto');
  ga('send', 'pageview');
</script>\n";
    return $str;
}

sub lock {
    my ($fh) = @_;
    flock( $fh, LOCK_EX );

    # and, in case someone appended while we were waiting...
    seek( $fh, 0, SEEK_END );
}

sub unlock {
    my ($fh) = @_;
    flock( $fh, LOCK_UN );
}

=head2 read_sqs
    
    About   : Subroutine that sends systems calls
    Usage   : None             
    Args    : 
    Info    : Two options to monitor status
              a) Have a status file - Ideal when there are many steps on the pipeline
              b) Read qstat and parse it <<<<<<<<<<<  CHOSEN
    
=cut

sub read_sqs {

    my $page           = shift;
    my %job            = ();
    my $total_job      = 0;
    my $total_sample   = 0;
    my $total_finished = 0;
    my $total_running  = 0;
    my $total_queued   = 0;
    my $total_failed   = 0;

    # hash for displaying status in color
    my %status_button = (
        Running =>
          '<span class="btn-small btn-info" type="button">Running</span>',
        Queued =>
          '<span class="btn-small btn-warning" type="button">Queued</span>',
        Failed =>
'<span class="btn-small btn-danger" type="button">&nbsp Failed  &nbsp;</span>',
        Finished => '<span class="btn-small btn-success">Finished</span>'
    );

    # Running qstat ONCE and reading output
    my @jobs = `/pro/sqs-3.1/bin/qstat  | egrep -w 'www-data|apache'`;
    chomp @jobs;

    # Now processing each line
    for my $job (@jobs) {
        $job =~ s/^ +//;    # Getting rid of the leading white space(s)
        my @tmp_fields = split / +/, $job;

        #splice @tmp_fields, 4, 1 if scalar @tmp_fields == 12;
        @tmp_fields = @tmp_fields[ 0, 2, 5, 6, 7, 8, 9 ];

        my $id     = $tmp_fields[0];
        my $job_id = $tmp_fields[1];

        # Only 17 chrs will be shown
        # LP6005830_DNA_A01
        # 12345678901234567
        $job_id =~ s/^job_x_//;    # We added _x_ to make it unique
        $job_id =~ s/\.sh//;

        my $date = join( ' ',
            $tmp_fields[2], $tmp_fields[3], $tmp_fields[4], $tmp_fields[5] );
        my $status = $tmp_fields[6];
        $job{$job_id}{'qstat-id'}     = $id;
        $job{$job_id}{'qstat-job_id'} = $job_id;
        $job{$job_id}{'qstat-date'}   = $date;
        $job{$job_id}{'qstat-status'} = $status;
    }

    # Get the directory list for status.json
    # Note that we will apply some filters
    my @json_array = ();    # Bidimensional array
    my $data_dir    = $page eq 'status' ? './data' : './wellderly';
    my $str_private = 'Private';
    my $row         = 0;
    opendir( my $dh, $data_dir );
    while ( readdir $dh ) {
        next if /\.|status\.json/;    # get rid of . .. .sqs/ etc...

        # Load info_txt to alleviate naming
        # It's TSV but we keep TXT for downloading and visualization purposes
        my $info_txt = "$data_dir/$_/info.txt";
        next unless -f $info_txt; # We only read directories that have $info_txt
        my $info_sqs = "$data_dir/$_/sgadviser_mtdna.sqs";

        # Count Total number of jobs
        $total_job++;

        # 1D of the hash will be job_id
        $job{$_}{'job_id'} = $_;

        # Fill the hash with contents from info.tsv
        # We need maximum speed so we avoid shell (e.g., ``)
        my $str_info = '';
        open( my $fh1, '<', $info_txt );
        while ( defined( my $line = <$fh1> ) ) {
            next unless $. == 3;
            chomp $line;
            $str_info = $line;
        }
        close $fh1;
        my @info_fields = split /\t/, $str_info;

        $job{$_}{'date'}   = $info_fields[0];
        $job{$_}{'sample'} = $info_fields[3];
        $job{$_}{'bam'}    = $info_fields[4];

        $total_sample += $info_fields[3];

        # Checking privacy
        $job{$_}{'private'} = $info_fields[2];
        $job{$_}{'job_id'}  = $str_private if $job{$_}{'private'} eq 'yes';
        $job{$_}{'bam'}     = $str_private if $job{$_}{'private'} eq 'yes';

        my $sqs_id = '';
        open( my $fh2, '<', $info_sqs );
        while ( defined( my $line = <$fh2> ) ) {
            chomp $line;
            $sqs_id = $line;

            # Note that after restarting the machine $info_sqs may contain extra lines
            # But we only need the first one
            #  >>17
            #  >>
            #  >>Starting qseek daemon for www-data
            #  >>on mrueda-ws1 at Fri Jan 13 16:21:48 PST 2017."
            last;
        }
        close $fh2;
        $job{$_}{'id'} = $sqs_id;

        # If job appears in qstat then it can be:
        # a) Running
        # b) Queued
        # c) Cancelled
        if ( exists $job{$_}{'qstat-job_id'} ) {
            push @{ $json_array[$row] }, $job{$_}{'job_id'}, $job{$_}{'id'},
              $job{$_}{'sample'}, $job{$_}{'bam'},
              $job{$_}{'date'},   $status_button{ $job{$_}{'qstat-status'} };

            $total_running++ if $job{$_}{'qstat-status'} eq 'Running';
            $total_queued++  if $job{$_}{'qstat-status'} eq 'Queued';
        }

        # If the job it's not in qstat it can be:
        # a) Finished
        # b) Failed
        else {
            my $result_file = "$data_dir/$_/mit_prioritized_variants.txt";
            my $job_status  = -s $result_file ? 'Finished' : 'Failed';

            my $tmp_str = '';

            # Using a condifitional to decide what to print as Job_id
            if ( $job_status eq 'Finished' && $job{$_}{'private'} eq 'no' ) {
                $tmp_str = "<a href=\"job/" . $_ . '">' . $_ . '</a>';

                $total_finished++;
            }
            elsif ( $job_status eq 'Finished' && $job{$_}{'private'} eq 'yes' )
            {
                $tmp_str = $str_private;

                $total_finished++;

            }
            else {
                $total_failed++;
                $tmp_str = $_;
            }

            my $tmp_str_bis =
              $job{$_}{'private'} eq 'no' ? $job{$_}{'bam'} : $str_private;

            push @{ $json_array[$row] }, $tmp_str, $job{$_}{'id'},
              $job{$_}{'sample'},
              $tmp_str_bis, $job{$_}{'date'}, $status_button{$job_status};
        }
        $row++;
    }
    closedir $dh;

    # Encode 2D array to json and fix the tails
    my $str_json = encode_json \@json_array;
    $str_json =~ s/^/{"data":/;
    $str_json =~ s/$/\}/;

    #    $str_json .= Dumper \%job;

    my $status_json = $data_dir . '/status.json';
    open( my $fh, '>', $status_json );
    lock($fh);
    print $fh $str_json;
    unlock($fh);
    close $fh;

    # Count totals

    # End
    return (
        $total_job,     $total_sample, $total_finished,
        $total_running, $total_queued, $total_failed
    );
}

1;
