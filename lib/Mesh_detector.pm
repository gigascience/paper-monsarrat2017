#Copyright (C) 2017  Paul Monsarrat
#MultiReview Manager

#This program is free software: you can redistribute it and modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, version 3 of the License.

#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.

#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>.

package Mesh_detector;
use strict;
use Dancer ':syntax';
use Storable;
use LWP::UserAgent;
use Data::Dumper;
use File::Slurp;
use Text::Unidecode;
use utf8;
use HTML::Entities;

my %fna=('MH'=>'Mesh/Mesh.txt','MH2'=>'Mesh/InvertedMesh.txt','MH3'=>'Mesh/giMesh.txt','MH4'=>'Mesh/MRCONSOMesh.txt','LSMH'=>'mesh.txt','LSOMH'=>'listMESH.txt');
my %ini=('LSMH'=>undef,'LSOMH'=>undef);

sub tokenize {
    # Adapted from Vetle I. Torvik and Marc Weeber Copyright 2007, University of Illinois at Chicago
    my $ti = $_[0];
    #All lowercase
    $ti = lc $ti;
    #Replace parentheses and punctuation by spaces
    $ti =~ s/[\[\](),\.\";:!?&\^\/\*+-]/ /g;
    #Remove more than one space
    $ti =~ s/  +/ /g;
    #Remove initial and trailing spaces
    $ti =~ s/^ +//;
    $ti =~ s/ +$//;

    return $ti;
}

#Loading and formatting the MESH
sub Mesh{

        my $filename = 'Mesh/d2017.bin';
	my $content = read_file($filename,binmode=>':raw');
	$content=unidecode(decode_entities($content));

	my ($i,$j,$mh,$mh2,$mn,$ligne,$ligne2,$ligne3)=(0,0,"","","","","","");
	my (%mesh,%mesh2,%mesh3,%mesh4)=((),(),(),());
        my $count=0;

	while ($content=~m/(?:NEWRECORD)(.*?)(?:UI\s=\s)/sg){
              	$count++;
                info $count;
        	$ligne=$1;
                $ligne2=$ligne;
                $ligne3=$ligne;

                if($ligne3=~m/(?:MH\s=\s)([^\n\|]*)/sg){
                	$mh2=$1;
                        $mh2 =~ s/,/./gi;
                        while($ligne=~m/(?:(?:MH\s=\s)|(?:ENTRY\s=\s))([^\n\|]*)/sg){
                                $mh=$1;
                                $mh =~ s/,/./gi;
                                $i++;
                                while($ligne2=~m/MN\s=\s([^\n\|]*)/sg){
                                        $mn=$1;
                                        my $mhbis=$mh;
                                        $mhbis=tokenize($mhbis);
                                        $mesh3{$mhbis}{'OK'}=$mh2;
                                        $mesh{$mh}{'MN'}{$mn}{'Nom'}=$mh2;
                                        $mesh2{$mn}{'Nom'}=$mh2;
                                }
                        }
                }
	}
	store \%mesh, $fna{'MH'};
	store \%mesh2, $fna{'MH2'};
	store \%mesh3, $fna{'MH3'};

	open FICHIER,"< Mesh/MRCONSO.RRF" or die "MeSH file not available";
        my $count=0;
	while (my $ligne= <FICHIER>){
	        chomp $ligne;
                $count++;
                info $count;
              	my @sepitem=split(/\|/,$ligne);
                $mesh4{"NAME"}{tokenize($sepitem[14])}=$sepitem[0]; #For Strings
                if ($sepitem[11] eq "MSH"){
                	$mesh4{"CUI"}{$sepitem[0]}.=$sepitem[14].'|'; #For CUI
	        }
	}
	close FICHIER;
	store \%mesh4, $fna{'MH4'};
}

#Mesh detection to take into account Mesh keywords as well as free keywords
sub meshdetection{
	my ($meshrefs,$actualxml,$pmid,$listmesh,$mesh,$mesh3,$year,$countmesh,$mesh4)=($_[0],$_[1],$_[2],$_[3],$_[4],$_[5],$_[6],$_[7],$_[8]);
        my %meshtemp=();

	foreach my $key (sort keys %{$meshrefs}){
                  my $meshclefprojet=$key;
                  $meshclefprojet=tokenize($meshclefprojet);
                  if(defined($mesh->{$key})){
                  	print $listmesh "$actualxml\t$pmid\t$key\n";
                        $countmesh->{$year}++;
                  }
                  else{
                        if(defined($mesh3->{$meshclefprojet})){
                        	$meshclefprojet=$mesh3->{$meshclefprojet}->{'OK'};
                        	print $listmesh "$actualxml\t$pmid\t$meshclefprojet\n";
                                $countmesh->{$year}++;
                        }
                        else{
                  		if(defined($mesh4->{"NAME"}->{$meshclefprojet})){
                                        my @sepitem=split(/\|/,$mesh4->{"CUI"}->{$mesh4->{"NAME"}->{$meshclefprojet}});
                                        foreach my $temp (@sepitem){
                                        	if($temp ne "" && defined($mesh->{$temp})){
                  						print $listmesh "$actualxml\t$pmid\t$temp\n";
                        					$countmesh->{$year}++;
                                                }
                                        }
                                }
                        }
                  }
	}
}

#Subroutine to extract only C and G sub-branches (only the first level was finally considered)
sub meshes{
        #Initialisation of files
	my $mesh = retrieve($fna{'MH'});
	my $mesh2 = retrieve($fna{'MH2'});
        my $count=0;
        my %temp=();
        open(LSMH, '<', $fna{'LSMH'}) or die "Could not open file '$fna{'LSMH'}' $!";
        while( my $line = <LSMH> ) {
               chomp($line) ;
               $count++;
               if($count>1){
               		my @sepitem=split(/\t/,$line);
               		foreach my $key (sort keys %{$mesh->{$sepitem[2]}->{'MN'}}){
                  		if($key=~m/^([CG]\d\d)/){$temp{$sepitem[1]}{$mesh2->{$1}->{'Nom'}}=1;}
                        }
               }
        }
        close LSMH;

    	open($ini{'LSOMH'}, '>', $fna{'LSOMH'}) or die "Could not open file '$fna{'LSOMH'}' $!";
        print {$ini{'LSOMH'}} "pmid\tmesh\n";
        foreach my $key (sort keys %temp){
        	foreach my $key2 (sort keys %{$temp{$key}}){
	                print {$ini{'LSOMH'}} "$key\t$key2\n";
                }
        }
        close $ini{'LSOMH'};
}

#Subroutine to extract only C and G sub-branches (only the first level was finally considered)
sub meshperio{
        #Initialisation of files
	my $mesh = retrieve($fna{'MH'});
	my $mesh2 = retrieve($fna{'MH2'});
        my $count=0;
        my %temp=();
        open(LSMH, '<', $fna{'LSMH'}) or die "Could not open file '$fna{'LSMH'}' $!";
        while( my $line = <LSMH> ) {
               chomp($line) ;
               $count++;
               if($count>1){
               		my @sepitem=split(/\t/,$line);
               		foreach my $key (sort keys %{$mesh->{$sepitem[2]}->{'MN'}}){
                  		if($key=~m/^(C07)/){$temp{$sepitem[1]}{$mesh2->{$1}->{'Nom'}}=1;}
                        }
               }
        }
        close LSMH;

    	open($ini{'LSOMH'}, '>', $fna{'LSOMH'}) or die "Could not open file '$fna{'LSOMH'}' $!";
        print {$ini{'LSOMH'}} "pmid\tmesh\n";
        foreach my $key (sort keys %temp){
        	foreach my $key2 (sort keys %{$temp{$key}}){
	                print {$ini{'LSOMH'}} "$key\t$key2\n";
                }
        }
        close $ini{'LSOMH'};
}

true;