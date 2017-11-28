#Copyright (C) 2017  Paul Monsarrat

#This program is free software: you can redistribute it and modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, version 3 of the License.

#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.

#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>.

package ES_detector;
use Dancer ':syntax';
use Time::Local 'timelocal_nocheck';
use List::MoreUtils;
use strict;
use LWP::UserAgent;
use Storable qw(nstore retrieve freeze thaw dclone);
use Data::Dumper;
use XML::Twig;
use Load_module;
use Mesh_detector;
use Text::Unidecode;
use File::Slurp;
use utf8;
use HTML::Entities;
use Math::Round;
set session => 'Storable';

our $VERSION = '1.01';
my ($multivariate,$multivariate2,$adjusted)=(0,0,0);
my ($content,$count,$countes,$countpos,%countmesh,%countall,%countes,%countpos,%countpres,%countsr,$actualxml,$random_number,$random_ok)=("",0,0,0,(),(),(),(),(),(),0,0,0);
my (%rand,%countries,%provinces,%doajs)=((),(),(),());
my ($mesh,$mesh2,$mesh3,$mesh4,$list)=(undef,undef,undef,undef,undef);
my %fna=('SSZ'=>'listSSZ.txt','MAPA'=>'PubMedFiles/Mapaffil/mapaffil2015.tsv','LSFFT'=>'listFFT.txt','LSPMC'=>'listOR_PMC.txt','LSMH'=>'mesh.txt','LSOR'=>'listOR.txt','LSCO2'=>'listOR_countries2.txt','LSCO'=>'listOR_countries.txt','LSXML'=>'listXML.txt','LSRD'=>'listRANDOM.txt','StRD'=>'screenRANDOM','MH'=>'Mesh/Mesh.txt','MH2'=>'Mesh/InvertedMesh.txt','MH3'=>'Mesh/giMesh.txt','MH4'=>'Mesh/MRCONSOMesh.txt','AXML'=>'');
my %ini=('LSPMC'=>undef,'LSRD'=>undef,'LSXML'=>undef,'LSMH'=>undef,'LSOR'=>undef,'LSCO'=>undef);

#Extract mesh descriptor to compute ES by mesh keyword
get '/meshes' => sub {
	Mesh_detector::meshes;
        return template 'index';
};

#Load all Mesh descriptors
get '/mesh' => sub {
	Mesh_detector::Mesh;
        return template 'index';
};

get '/' => sub {

        return template 'index';
};

get '/clear' => sub {
        #Initialisation of files
        foreach my $i(keys %ini){open($ini{$i}, '>', $fna{$i}) or die "Could not open file '$fna{$i}' $!";}
        print {$ini{'LSMH'}} "xmlfile\tpmid\tmesh\n";
        print {$ini{'LSOR'}} "xmlfile\tid\tpmid\tyear\tmonth\tor\tlci\thci\torhrrr\tci\tcountries\tadjusted\tmultivariate\tsr\tccj\tdoaj\tpmc\tnlm\n";
        print {$ini{'LSCO'}} "xmlfile\tid\tpmid\tcountries\n";
        print {$ini{'LSXML'}} "xmlfile\tyear\ttotal_all\ttotal_abs\ttotal_abssr\ttotal_atleastone\ttotal_es\ttotal_mesh\n";
    	print {$ini{'LSRD'}} "xmlfile\tcount\tyear\tpmid\n";
        print {$ini{'LSPMC'}} "id\tpmid\tdispo\tor\tlci\thci\tci\torhrrr\tplace\n";
        foreach my $i(keys %ini){close $ini{$i};}
        my %refrandom=();
        nstore \%refrandom, $fna{'StRD'};

        session->destroy;
        session actualxml => 0;
        session actualpmid => 0;
        session actualcount => 0;
        return template 'index';
};

#New project loading xml files
get '/extract' => sub {

        #Random articles for specificity and sensibility
        $random_number = int(rand(1750));

        #Initialisation of files
	($mesh,$mesh2,$mesh3,$mesh4) = (retrieve($fna{'MH'}),$mesh2 = retrieve($fna{'MH2'}),$mesh3 = retrieve($fna{'MH3'}),$mesh4 = retrieve($fna{'MH4'}));

        #Load country files
        %countries=Load_module::load_countries();
        %provinces=Load_module::load_provinces();
    	$content=Load_module::load_ccj();
        %doajs=Load_module::load_doaj();

        my $twig= new XML::Twig(TwigHandlers => {"PubmedArticle/MedlineCitation"  => \&MedlineCitation  },twig_roots => { MedlineCitation => 1});
        my $rep = "PubMedFiles";
        my $numfile="";
        chdir $rep;
        my @ListeXML = <*.xml>;
        chdir "../";
        foreach(@ListeXML) #Parse xml files
        {
                my $file=$_;
                if ($file =~ m/medline\d\dn0*([1-9]\d*)/){
                	$numfile=$1;
                        $actualxml=session('actualxml');
                        if($numfile > $actualxml){
        			foreach my $i(keys %ini){open($ini{$i}, '>>', $fna{$i}) or die "Could not open file '$fna{$i}' $!";}
        	               	session actualxml => $numfile;
                                $actualxml=$numfile;
                                my $rep="PubMedFiles/".$file;
                                $fna{'AXML'}='PubMedFiles/all_'.$actualxml.'.txt';
                                open(ALLES, '>', $fna{'AXML'}) or die "Could not open file '$fna{'AXML'}' $!";
                                ($count,$countes,$countpos,%countall,%countes,%countpos,%countpres,%countsr,%countmesh)=(0,0,0,(),(),(),(),(),());
                                $twig->parsefile($rep);
                                foreach my $temp (keys %countall){
                                        if(not defined($countpos{$temp})){$countpos{$temp}=0;}
                                        if(not defined($countes{$temp})){$countes{$temp}=0;}
                                        if(not defined($countpres{$temp})){$countpres{$temp}=0;}
                                        if(not defined($countsr{$temp})){$countsr{$temp}=0;}
                                        print {$ini{'LSXML'}} "$actualxml\t$temp\t$countall{$temp}\t$countpres{$temp}\t$countsr{$temp}\t$countpos{$temp}\t$countes{$temp}\t$countmesh{$temp}\n";
                                }
                        	session actualcount => 0;
                                close ALLES;
                                foreach my $i(keys %ini){close $ini{$i};}
                                info "PAUSE 10s";
                                sleep 10;
                        }
                }
        }

        ($mesh,$mesh2,$mesh3,$mesh4)=(undef,undef,undef,undef);
        return template 'index';
};

sub MedlineCitation {

	#Extraction of data from xml files
        my($twig, $MedlineCitation)= @_;
        my $actualcount=session('actualcount');
        $count++;

        if($count>$actualcount){
        	info "$actualxml $count";

        	#Initialization of data
	        my $pmid  = $MedlineCitation->field('PMID');
                my ($abstract,$title,$nlm,$pmc,$year,$month,$orhrrr,$ci,$sr,$issn,$issnl,$doaj,$ccj,$subregions,$namescountries,$once,$sig,$oncecmd)=("","","","","","","","",0,"","","","","","",0,0,0);

                #Algorithm for publication date extraction
                if(defined($MedlineCitation->first_child('Article')->first_child('Journal')->first_child('JournalIssue')->first_child('PubDate'))){
                        if($MedlineCitation->first_child('Article')->first_child('Journal')->first_child('JournalIssue')->first_child('PubDate')->field('Year') ne ""){
                                $year  = $MedlineCitation->first_child('Article')->first_child('Journal')->first_child('JournalIssue')->first_child('PubDate')->field('Year');
                                if($MedlineCitation->first_child('Article')->first_child('Journal')->first_child('JournalIssue')->first_child('PubDate')->field('Month') ne ""){
                                        $month  = $MedlineCitation->first_child('Article')->first_child('Journal')->first_child('JournalIssue')->first_child('PubDate')->field('Month');
                                }
                                else{
                                        if ($MedlineCitation->first_child('DateCreated')->field('Year')==$year){
                                                $month=$MedlineCitation->first_child('DateCreated')->field('Month');
                                        }
                                        elsif ($MedlineCitation->first_child('DateCreated')->field('Year')==$year+1){
                                                $month="Decx";
                                        }
                                        else{
                                                if($MedlineCitation->first_child('Article')->first_child('Journal')->first_child('JournalIssue')->first_child('PubDate')->field('Season') ne ""){
                                                        $month=$MedlineCitation->first_child('Article')->first_child('Journal')->first_child('JournalIssue')->first_child('PubDate')->field('Season');
                                                }
                                        }
                                }
                        }
                        else{
                                if($MedlineCitation->first_child('Article')->first_child('Journal')->first_child('JournalIssue')->first_child('PubDate')->field('MedlineDate') ne ""){
                                        my $temp  = $MedlineCitation->first_child('Article')->first_child('Journal')->first_child('JournalIssue')->first_child('PubDate')->field('MedlineDate');
                                        if($temp =~ m/(\d\d\d\d)\W(\D\D\D)/){
                                                $year=$1;
                                                $month=$2;
                                        }
                                        elsif($temp =~ m/(\d\d\d\d)(?:\W\d\d)?/){
                                                $year=$1;
                                                $month="";
                                                if ($MedlineCitation->first_child('DateCreated')->field('Year')==$year){
                                                	$month=$MedlineCitation->first_child('DateCreated')->field('Month');
                                        	}
                                                elsif ($MedlineCitation->first_child('DateCreated')->field('Year')==$year+1){
                                                	$month="Decx";
                                        	}
                                        	else{
                                                	if($MedlineCitation->first_child('Article')->first_child('Journal')->first_child('JournalIssue')->first_child('PubDate')->field('Season') ne ""){
                                                        	$month=$MedlineCitation->first_child('Article')->first_child('Journal')->first_child('JournalIssue')->first_child('PubDate')->field('Season');
                                                	}
                                        	}
                                        }
                                }
                                elsif($MedlineCitation->first_child('Article')->first_child('ArticleDate')->field('Year') ne ""){
                                	$year=$MedlineCitation->first_child('Article')->first_child('ArticleDate')->field('Year');
                                        $month=$MedlineCitation->first_child('Article')->first_child('ArticleDate')->field('Month');
                                }
                        }
                }
                $countall{$year}++;
                my (%stat,%subregion,%atrisk,%refsmesh,%idcountries)=((),(),(),(),());

                #Extraction of abstract
                $random_ok=0;
	        my $duplicate_abstract = $MedlineCitation->first_child('Article')->field('Abstract');
                if(defined($MedlineCitation->first_child('Article')->first_child('Abstract'))){
                	$abstract = $MedlineCitation->first_child('Article')->field('Abstract');
                        if($abstract ne ""){
                        	$countpres{$year}++;
                                if($random_number == int(rand(1750))){$random_ok=1;} #For random abstracts
                        }
                        if(my @meshxml = $MedlineCitation->first_child('Article')->first_child('Abstract')->children('AbstractText')){
                                foreach my $meshxml (@meshxml){
                                        my $temp=$meshxml->att('Label');
                                        my $temp2=$meshxml->att('NlmCategory');
                                        if((defined($temp) && $temp =~ m/result/i) || (defined($temp2) && $temp2 =~ m/result/i)){
                                        	$abstract = $meshxml->text;
                                                last;
                                        }
                                }
                    	}
	        }
                else{
                	if(defined($MedlineCitation->first_child('Article')->first_child('OtherAbstract'))){
                        	$abstract = $MedlineCitation->first_child('Article')->field('OtherAbstract');
                                if($abstract ne ""){$countpres{$year}++;}
                        }
                }

                $abstract=unidecode(decode_entities($abstract));
                $duplicate_abstract=unidecode(decode_entities($duplicate_abstract));

                #Extract title
                $title  = $MedlineCitation->first_child('Article')->field('ArticleTitle');
                if($title =~ m/((?:systematic\s*review)|(?:meta.?analys)|(?:review))/i){$sr=1;}

                #Identify Reviews
                if(defined($MedlineCitation->first_child('Article')->first_child('PublicationTypeList'))){
                	if(my @affiliations = $MedlineCitation->first_child('Article')->first_child('PublicationTypeList')->children('PublicationType')){
                        	@affiliations = $MedlineCitation->first_child('Article')->first_child('PublicationTypeList')->children('PublicationType');
                              		foreach my $affiliations (@affiliations){
                                        	my $temp=$affiliations->text;
                                                if($temp eq "Review" || $temp eq "Meta-Analysis"){$sr=1;}
                                        }
                        }
                }

                #Mesh keywords and Reviews
                if(defined($MedlineCitation->first_child('MeshHeadingList'))){
                    if(my @meshxml = $MedlineCitation->first_child('MeshHeadingList')->children('MeshHeading')){
                            foreach my $meshxml (@meshxml){
                                    my $temp=$meshxml->field('DescriptorName');
                                    if($temp =~ m/(?:(?:meta.?analysis)|(?:review))/i){$sr=1;}
                                    $temp =~ s/,/./gi;
                                    $refsmesh{$temp}=1;
                            }
                    }
                }
                if(defined($MedlineCitation->first_child('KeywordList'))){
                    if(my @meshxml = $MedlineCitation->first_child('KeywordList')->children('Keyword')){
                            foreach my $meshxml (@meshxml){
                                    my $temp=$meshxml->text;
                                    if($temp =~ m/(?:(?:meta.?analysis)|(?:review))/i){$sr=1;}
                                    $temp =~ s/,/./gi;
                                    $refsmesh{$temp}=1;
                            }
                    }
                }
                if($abstract ne "" && $sr==1){$countsr{$year}++;}

	        #Transformation of data (remove percentages, special characters, currencies and p-values to gain in performance)
                $abstract=~s/9[059]\s?%//gi;
                $abstract=~s/(?:\d{1,3}(?:\.\d+)?|(?:\.\d+))\s?(?:(?:\+\/-)|pm|(?:\+-)|(?:\+\/-))\s?(?:\d{1,3}(?:\.\d+)?|(?:\.\d+))//gi;
	        $abstract=~s/(\d+(?:\.\d+)?)(?:\s?(?:-|to|vs|and|,|\/)\s?(?1))*\s?%//gi;
	        $abstract=~s/\*/\./gi;
	        $abstract=~s/\W(?:p\s*(?:=|<=|>=|<|>|\[\?\]))(?:\s*[01](?:\.\d+)?)//gi;
                $abstract=~s/\[\?\]//gi;
                $abstract=~s/(?:\W\d+(?:,\d+)?)\s?(?:euros?|(?:(?:CAN|US|A)?(?:\$|dollars))|yens?|EUR|PS|GBP|Y=)|(?:euros?|(?:(?:CAN|US|A)?(?:\$|dollars))|yens?|EUR|PS|GBP|Y=)\s?(?:\d+(?:,\d+)?)//gi;
                $abstract=~s/((?:\d+,\d{3}(?<!\d))|(?:\d{1,4}(?:\.\d+)?|(?:\.\d+)))(?:-?)(?:(?:\s?(?:-|and|,|vs|to|\/)\s?(?1))*|-?)\s*(?:(?:tera|giga|mega|kilo|hecto|deci|centi|milli|micro|nano|pico)-?|(?:[TGMkhdcmµunp]|mu))?(?:(?:meters?|grams?|amperes?|moles?|octets?|liters?)|(?:[mMgALlo]|mol))(?:\W-?\d\W|\d\W|\W)//g;
                $abstract=~s/((?:\d+,\d{3}(?<!\d))|(?:\d{1,4}(?:\.\d+)?|(?:\.\d+)))(?:-?)(?:(?:\s?(?:-|and|,|vs|to|\/)\s?(?1))*|-?)\s*(?:(?:[dD]ays?|[mM]inutes?|[Hh]ours?|[Ss]econds?|[mM]onths?|[yY]ears?|[Aa]ngstroms?|[Bb]ars?|[Hh]ectares?|[Dd]ecibels?|[dD]egrees?|[bBecquerel]|[Gg]ray|[lL]umens?|[Ll]ux|[kK]elvin|[cC]elsius|[cC]andela)|(?:[AKCydmh°]|hrs?|mins?|mmHg|Hg|ha|dB|degs?|Gy|cd|lm|lx|Bq|[Yy]o|[Mm]o))(?:\W-?\d\W|\d\W|\W)//g;
                $abstract=~s/((?:\d+,\d{3}(?<!\d))|(?:\d{1,4}(?:\.\d+)?|(?:\.\d+)))(?:-?)(?:(?:\s?(?:-|and|,|vs|to|\/)\s?(?1))*|-?)\s*(?:(?:mega|kilo|milli|micro)-?|(?:[Mkmµu]))?(?:(?:[rR]adians?|[hH]ertz|[nN]ewtons?|[pP]ascals?|[wW]atts?|[sS]ievert|[jJ]oules?|[vV]olts?|[dD]altons?|[eE]lectron-?volts?)|(?:rads?|[Hh]z|[NJWV]|Sv|Pa|eV))(?:\W-?\d\W|\d\W|\W)//g;
                ($multivariate,$multivariate2,$adjusted)=(0,0,0);

                while($abstract =~ m/((?:(?:(?<!un)|(?<!not)|(?<!non)|(?<!no))\W?[aA]djust)?.{0,50}?\W[aA]?)((?:[Rr]elatives?\W*[Rr]ates?)|(?:[Rr]elatives?\W*[Rr]isks?)|(?:(?:[Rr]elatives?\W*[Rr]isks?)|(?:[Hh]a[sz]ards?\W*[Rrates?])|(?:[Pp]revalences?\W*[Rrates?])|(?:[Pp]revalences?\s[Oo]dds?)|(?:[Rr]isks?)|(?:[Oo]dds?)|(?:[Hh]a[sz]ards?)|(?:[Pp]revalences?)|(?:(?:[Ii]ncidences?)?[Rr]ates?))\W*[Rr]atios?|(?:POR|por|Por|OR|IRR|irr|Irr|rrr|RRR|Rrr|hrr|HRR|HR|PRR|Prr|prr|PR|rr|RR|Rr))([sAa]?(?:djusted|crude)?\W)(.*?((?<!\d,)\d{1,3}(?:\.\d+)?|(?:\.\d+)).*?(?=\W[aA]?(?2).*)|.*(?!(?2)))/g){
                	my ($c1,$c2,$c3,$abstractpart)=(defined($1)?$1:"",defined($2)?$2:"",defined($3)?$3:"",defined($4)?$4:"");
                        my $uniquees=0;
                        my $ortemp=$c2;
	                $ortemp=~s/^[aA\s]//;
	                $ortemp=substr($ortemp,0,1);
	                if($ortemp eq "H" || $ortemp eq "h"){$orhrrr="HR";}
	                if($ortemp eq "O" || $ortemp eq "o"){$orhrrr="OR";}
	                if($ortemp eq "R" || $ortemp eq "r"){$orhrrr="RR";}
                        if($ortemp eq "I" || $ortemp eq "i"){$orhrrr="RR";}
                        if($ortemp eq "P" || $ortemp eq "p"){$orhrrr="PR";}

	                #Looking for multivariate analysis
                        $ortemp=$orhrrr;
                        if(substr($c3,0,1) =~ m/([as])/i){
                        	$ortemp = uc $1;
                                $ortemp=$orhrrr.$ortemp;
                        	if($ortemp eq "A"){$adjusted=1;}
                        }
                        if(substr($c1,-1) =~ m/a/i){
                        	$adjusted=1;
                                $ortemp="A".$ortemp;
                        }
                        if($c1 =~ m/(?:(?<!un)|(?<!not)|(?<!non)|(?<!no))\W?adjust/i){$adjusted=1;}
                        if(substr($abstractpart,0,50) =~ m/(?:(?<!un)|(?<!not)|(?<!non)|(?<!no))\W?adjust/i){$adjusted=1;}
                        if($adjusted==1){$multivariate=1;}

                        my $cx="";
                        while($abstractpart =~ m/(.*?)(?<![-\w\.])((?<!\d,)\d{1,3}(?:\.\d+)?|(?:\.\d+))([^\.\/\)\}\]\w]\D*?(?<![-\.\w<>]))((?2))([^=\+<>\.\/\)\}\]\w][^\d=\+<>]*?(?<![=\+<>\(\{\[\w]))((?2))(?![0-9]|\.[0-9])(?(?{($2<=$4||$2>=$6)})1)/g){
                                $cx=defined($1)?$1:"";
                                my ($c4,$c5,$c6,$c7,$c8)=(defined($2)?$2:"",defined($3)?$3:"",defined($4)?$4:"",defined($5)?$5:"",defined($6)?$6:"");
                                $uniquees++;

                                if($oncecmd==0){
                                    $oncecmd++;

                                    #Define if a risk can be detected inside the abstract
                                    %atrisk=Load_module::identify_abs_atrisk($duplicate_abstract);

                                    #Confidence interval
                                    $ci="";
                                    if($duplicate_abstract =~ m/(?:[Cc]onfidence\s+(?:[Ii]ntervals?|[Ll]imits?\s?|[Ll]evels?)|CI|c\.?i\.?)\D{1,10}(9[059])\W?(?:%|per\W?cent)?|[^\.0-9](9[059])\W?(?:%|per\W?cent)?\D{1,10}(?:[Cc]onfidence\s+(?:[Ii]nterval|[Ll]imits?\s?|[Ll]evels?)|CI|c\.?i\.?)/){
                                            if (defined($1)){$ci=$1;}
                                            if (defined($2)){$ci=$2;}
                                            $ci=$ci."%";
                                    }

                                    #Extraction of the journal id
                                    $issn=$MedlineCitation->first_child('Article')->first_child('Journal')->field('ISSN');
                                    $nlm  = $MedlineCitation->first_child('MedlineJournalInfo')->field('NlmUniqueID');
                		    if(defined($MedlineCitation->first_child('MedlineJournalInfo')->field('ISSNLinking'))){$issnl  = $MedlineCitation->first_child('MedlineJournalInfo')->field('ISSNLinking');}

                                    #Test for PMC article
                                    if(my @meshxml = $MedlineCitation->children('OtherID')){
                                          foreach my $meshxml (@meshxml){
                                                  my $temp=$meshxml->text;
                                                  if($temp =~ m/(PMC\d+)/){
                                                            $pmc = $1;
                                                            last;
                                                  }
                                          }
                                    }

                                    #Obtain information about core clinical or Open Acces journals
                                    if(((defined($issn) && $issn ne "" && $issn ne " ") || (defined($issnl) && $issnl ne "" && $issnl ne " ")) && (defined($doajs{$issn}) || defined($doajs{$issnl}))){$doaj=1;}
                                    else{$doaj=0;}
                                    if($content =~ m/ISSN.*$issn/ || $content =~ m/ISSN.*$issnl/ || $content =~ m/NLM ID.*$nlm/){$ccj=1;}
                                    else{$ccj=0;}

                                    #Extraction of data from xml files: affilitations for countries
                                    my $temp="";
                                    if(defined($MedlineCitation->first_child('Article')->first_child('AuthorList'))){
                                        if(my @affiliations = $MedlineCitation->first_child('Article')->first_child('AuthorList')->children('Author')){
                                                @affiliations = $MedlineCitation->first_child('Article')->first_child('AuthorList')->children('Author');
                                                foreach my $affiliations (@affiliations){$temp.=" ".$affiliations->field('AffiliationInfo');}
                                        }
                                    }
                                    %idcountries=Load_module::identify_countries(\%countries,$temp,\%provinces);
                                    if($duplicate_abstract =~ m/(?:(?<!un)|(?<!not)|(?<!non)|(?<!no))\W?adjust|multivaria/i){$multivariate=1;}
                                    if($duplicate_abstract =~ m/confoundings?\sfactors?|controlling\sfor/i){$multivariate2=1;}
                        	}

	                	#Checking of the lengths of the strings
                        	if(length($c5)<=100 && length($c7)<=10){
                        		my $ortemp2=uc $ortemp;
                                	my $atriskyn="";
                                        if(length($c2)<=4){
                                        	if(defined($atrisk{$ortemp2})){
                                                	$atriskyn=$atrisk{$ortemp2};
                                                }
                                        }
                                        if(int($c4) eq "$c4" && int($c6) eq "$c6" && int($c8) eq "$c8"){$atriskyn="WARNING";}
                                        if(($c7 =~ m/,/ || length($cx)>200) && int($c4) eq "$c4" && int($c6) eq "$c6" && int($c8) eq "$c8"){$atriskyn="DANGER";}
	                        	if(substr($c4,0,1) eq '.'){$c4='0'.$c4;}
	                                if(substr($c6,0,1) eq '.'){$c6='0'.$c6;}
	                                if(substr($c8,0,1) eq '.'){$c8='0'.$c8;}

                                        if ($c4>$c6 && $c4<$c8 && $c4>0 && $c6>0 && $c8>0 && $atriskyn ne "DANGER" && !($atriskyn eq "WARNING" && $ci eq "")){
                                                $countes++;
                                                $countes{$year}++;
                                                my $or=$ci." ".$ortemp."=".$c4."[".$c6.",".$c8."] A".$adjusted." M".$multivariate." SR".$sr." ATRISK ".$atriskyn;
                                                if($once==0){$once++;}

                                                #To verify all extractions when a ES was detected
                                                print ALLES "$or\n";

                                                my @orbrut=($c4,$c6,$c8);
                                                $subregions="";
                                                $namescountries="";
                                                %subregion=();
                                                foreach my $temp(sort keys (%idcountries)){
                                                        if(not defined($subregion{$idcountries{$temp}})){
                                                                $subregion{$idcountries{$temp}}=1;
                                                                if($subregions ne ""){
                                                                        $subregions.=",$idcountries{$temp}";
                                                                        $namescountries.=",$temp";
                                                                }
                                                                if($subregions eq ""){
                                                                        $subregions.="$idcountries{$temp}";
                                                                        $namescountries.="$temp";
                                                                }
                                                        }
                                                        print {$ini{'LSCO'}} "$actualxml\t$countes\t$pmid\t$temp\n";
                                                }
                                                print {$ini{'LSOR'}} "$actualxml\t$countes\t$pmid\t$year\t$month\t$orbrut[0]\t$orbrut[1]\t$orbrut[2]\t$orhrrr\t$ci\t$subregions\t$adjusted\t$multivariate\t$sr\t$ccj\t$doaj\t$pmc\t$nlm\n";
                                        }
	                	}
	        	}
                if(substr($abstractpart,-15) =~ m/(?:(?<!un)|(?<!not)|(?<!non)|(?<!no))\W?adjust/i){$adjusted=1;}
                }
	        if($once!=0){
                	$countpos{$year}++;
                        $countpos++;
                        Mesh_detector::meshdetection(\%refsmesh,$actualxml,$pmid,$ini{LSMH},$mesh,$mesh3,$year,\%countmesh,$mesh4);
                        print ALLES "PMID $actualxml-$count|$countpos: $pmid\n$abstract\n$duplicate_abstract\n\n";
                        if($random_ok==1){print {$ini{'LSRD'}} "$actualxml\t$count\t$year\t$pmid\n";}
                }
                else{
                	if($random_ok==1){print {$ini{'LSRD'}} "$actualxml\t$count\t$year\t$pmid\n";}
                }

                session actualpmid => $pmid;
	        session actualcount => $count;
	        $twig->purge;
	}
};

#Data from PMC were downloaded before to be processed. The list of articles (PMC list) was generated from the Pubmed data mining part.
get '/downloadPMC' => sub {
	my $count=0;
        open(LSOR, '<', $fna{'LSOR'}) or die "Could not open file '$fna{'LSOR'}' $!";
        while(my $line = <LSOR>){
        info $count;
               chomp($line);
               $count++;

               if($count>1){
               		my @sepitem=split(/\t/,$line);
                      	info "$count";
                        if(defined ($sepitem[16]) && $sepitem[16] =~ m/PMC/){
                        	my $filename = 'PubMedFiles/PMC/pmc_download_'.$sepitem[16].'.txt';
	                        unless (-e $filename && -s $filename){
	                              open(PMC, '>', $filename) or die "Could not open file '$filename' $!";
	                              my $ua = new LWP::UserAgent;
	                              my $url = 'http://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pmc&id='.$sepitem[16].'&retmode=xml';
	                              my $response = $ua->get($url);
	                              unless ($response->is_success) {
	                                      die $response->status_line;
	                              }
	                              my $content = $response->content;
	                              print PMC "$content";
                                      info "$sepitem[16]";
                                      close PMC;
	                        }
                        }
               }
        }
        close LSOR;
        return template 'index';
};

#Each text file is read in order to be submitted to the data mining subroutine
get '/extractPMC' => sub {
        my $pmid=$_[0];
	my $count=0;
        my $countes=0;
        my %unique=();
        open(LSOR, '<', $fna{'LSOR'}) or die "Could not open file '$fna{'LSOR'}' $!";
        while( my $line = <LSOR> ) {
               chomp($line) ;
               $count++;
               if($count>1){
                        my @sepitem=split(/\t/,$line);
                        info "$count";
                        if(defined ($sepitem[16]) && !defined($unique{$sepitem[16]}) && $sepitem[16] =~ m/PMC/){
                        	$unique{$sepitem[16]}=1;
                            	my $filename = 'PubMedFiles/PMC/pmc_download_'.$sepitem[16].'.txt';
	                        my $content = read_file($filename);
	                        $content=unidecode(decode_entities($content));
	                        PMCArticle($content,$sepitem[2]);
                        }
                }
        }
        close LSOR;
        return template 'index';
};

#Subroutine to make data mining on PMC articles
sub PMCArticle{

  	my $PMCArticle=$_[0];
        my $pmid=$_[1];
	open($ini{'LSPMC'}, '>>', $fna{'LSPMC'}) or die "Could not open file '$fna{'LSPMC'}' $!";

        if($PMCArticle !~ m/<table frame(?:.*?)rules(?:.*?)>(?:.*?)<\/table>/sg && $PMCArticle !~ m/<\/abstract>(?:.*?)<title>Results(?:.*?)<title>Discussion/si){print {$ini{'LSPMC'}} "\t$pmid\t0\t\t\t\t\t\t\n";}
    	while($PMCArticle =~ m/<table frame(?:.*?)rules(?:.*?)>(.*?)<\/table>/sg){     #Each table is considered
        	my $tables=$1;

                #Transformation of data (remove percentages, special characters, currencies and p-values to gain in performance)
                $tables=~s/9[059]\s?%//gi;
                $tables=~s/(?:\d{1,3}(?:\.\d+)?|(?:\.\d+))\s?(?:(?:\+\/-)|pm|(?:\+-)|(?:\+\/-))\s?(?:\d{1,3}(?:\.\d+)?|(?:\.\d+))//gi;
	        $tables=~s/(\d+(?:\.\d+)?)(?:\s?(?:-|to|vs|and|,|\/)\s?(?1))*\s?%//gi;
	        $tables=~s/\*/\./gi;
	        $tables=~s/\W(?:p\s*(?:=|<=|>=|<|>|\[\?\]))(?:\s*[01](?:\.\d+)?)//gi;
                $tables=~s/\[\?\]//gi;
                $tables=~s/(?:\W\d+(?:,\d+)?)\s?(?:euros?|(?:(?:CAN|US|A)?(?:\$|dollars))|yens?|EUR|PS|GBP|Y=)|(?:euros?|(?:(?:CAN|US|A)?(?:\$|dollars))|yens?|EUR|PS|GBP|Y=)\s?(?:\d+(?:,\d+)?)//gi;
                $tables=~s/((?:\d+,\d{3}(?<!\d))|(?:\d{1,4}(?:\.\d+)?|(?:\.\d+)))(?:-?)(?:(?:\s?(?:-|and|,|vs|to|\/)\s?(?1))*|-?)\s*(?:(?:tera|giga|mega|kilo|hecto|deci|centi|milli|micro|nano|pico)-?|(?:[TGMkhdcmµunp]|mu))?(?:(?:meters?|grams?|amperes?|moles?|octets?|liters?)|(?:[mMgALlo]|mol))(?:\W-?\d\W|\d\W|\W)//g;
                $tables=~s/((?:\d+,\d{3}(?<!\d))|(?:\d{1,4}(?:\.\d+)?|(?:\.\d+)))(?:-?)(?:(?:\s?(?:-|and|,|vs|to|\/)\s?(?1))*|-?)\s*(?:(?:[dD]ays?|[mM]inutes?|[Hh]ours?|[Ss]econds?|[mM]onths?|[yY]ears?|[Aa]ngstroms?|[Bb]ars?|[Hh]ectares?|[Dd]ecibels?|[dD]egrees?|[bBecquerel]|[Gg]ray|[lL]umens?|[Ll]ux|[kK]elvin|[cC]elsius|[cC]andela)|(?:[AKCydmh°]|hrs?|mins?|mmHg|Hg|ha|dB|degs?|Gy|cd|lm|lx|Bq|[Yy]o|[Mm]o))(?:\W-?\d\W|\d\W|\W)//g;
                $tables=~s/((?:\d+,\d{3}(?<!\d))|(?:\d{1,4}(?:\.\d+)?|(?:\.\d+)))(?:-?)(?:(?:\s?(?:-|and|,|vs|to|\/)\s?(?1))*|-?)\s*(?:(?:mega|kilo|milli|micro)-?|(?:[Mkmµu]))?(?:(?:[rR]adians?|[hH]ertz|[nN]ewtons?|[pP]ascals?|[wW]atts?|[sS]ievert|[jJ]oules?|[vV]olts?|[dD]altons?|[eE]lectron-?volts?)|(?:rads?|[Hh]z|[NJWV]|Sv|Pa|eV))(?:\W-?\d\W|\d\W|\W)//g;

                my ($counttable,$orhrrr)=(0,"");
                my %soa=();
                my (@thead,@tbody)=((),());
                my ($line,$column)=(-1,-1);

                while($tables =~ m/<(thead|tbody)>(.*?)<\/\1>/sg){   #Head and body are first separated
                my $headorbody=$1;
                my $parts=$2;
                      while($parts =~ m/<tr>(.*?)<\/tr>/sg){   #The table is read line by line (TR tag)
                              my $lines=$1;
                              $line++;
                              $column=-1;
                              while($lines =~ m/(<(t[hd]).*?)(?:\/>|>(.*?)<\/\2>)/sg){   #The TD and TH tags are extracted to look for columns

                                      my ($tval,$span)=("","");
                                      my $thd=$1;
                                      my ($rowspan,$colspan)=(1,1);
                                      if(defined($3)){$tval=$3;}
                                      if(defined($1)){
                                              $span=$1;
                                              if($span =~ m/colspan.*?(\d)/s){$colspan=$1;}   #To consider merged columns
                                              if($span =~ m/rowspan.*?(\d)/s){$rowspan=$1;}   #To consider merged lines
                                      }

                                      if($headorbody eq "thead"){      #Table rebuilt into memory
                                              $column++;
                                              while(defined($thead[$line][$column])){$column++;}
                                              $thead[$line][$column]=$tval;
                                              if($tval =~ m/([a\W]*?)((?:[Rr]elatives?\W*[Rr]ates?)|(?:[Rr]elatives?\W*[Rr]isks?)|(?:(?:[Rr]elatives?\W*[Rr]isks?)|(?:[Hh]a[sz]ards?\W*[Rrates?])|(?:[Pp]revalences?\W*[Rrates?])|(?:[Pp]revalences?\s[Oo]dds?)|(?:[Rr]isks?)|(?:[Oo]dds?)|(?:[Hh]a[sz]ards?)|(?:[Pp]revalences?)|(?:(?:[Ii]ncidences?)?[Rr]ates?))\W*[Rr]atios?|(?:POR|por|Por|OR|IRR|irr|Irr|rrr|RRR|Rrr|hrr|HRR|HR|PRR|Prr|prr|PR|rr|RR|Rr))([sAa]?(?:djusted|crude)?\W*[^pP\s]?)/){    #Data mining to extract ES while preventing p values
                                                      my $ortemp=$2;
                                                      my $orhrrr="";
                                                      $ortemp =~ s/^[aA\s]//;
                                                      $ortemp=substr($ortemp,0,1);    #Find the type of ES
                                                      if($ortemp eq "H"||$ortemp eq "h"){$orhrrr="HR";}
                                                      if($ortemp eq "O"||$ortemp eq "o"){$orhrrr="OR";}
                                                      if($ortemp eq "R"||$ortemp eq "r"){$orhrrr="RR";}
                                                      if($ortemp eq "I"||$ortemp eq "i"){$orhrrr="RR";}
                                                      if($ortemp eq "P"||$ortemp eq "p"){$orhrrr="PR";}
                                                      $soa{$column}=$orhrrr;   #Identifying columns with ES
                                              }
                                              for (my $l = 1; $l <$rowspan; $l++) {
                                                      $thead[$line+$l][$column]="Empty";
                                              }
                                              for (my $c = 1; $c <$colspan; $c++) {
                                                      $column++;
                                                      $thead[$line][$column]="Empty";
                                              }
                                      }
                                      if($headorbody eq "tbody"){     #Once the columns with ESs identified, all values are extracted
                                              $column++;
                                              while(defined($tbody[$line][$column])){$column++;}
                                              $tbody[$line][$column]=$tval;
                                              if(defined($soa{$column}) && $soa{$column} ne ""){
                                                      if($tval =~ m/((?<!\d,)\d{1,3}(?:\.\d+)?|(?:\.\d+))/i){
                                                      		$countes++;
                                                      		if($1 ne ""){print {$ini{'LSPMC'}} "$countes\t$pmid\t1\t$1\t\t\t\t$soa{$column}\tTables\t\n";}
                                                      }
                                              }
                                              for (my $l = 1; $l <$rowspan; $l++) {
                                                      $tbody[$line+$l][$column]="Empty";
                                              }
                                              for (my $c = 1; $c <$colspan; $c++) {
                                                      $column++;
                                                      $tbody[$line][$column]="Empty";
                                              }
                                      }
                              }
                      }
                }
        }

        $PMCArticle =~ s/<table-wrap id(.*?)>(.*?)<\/table-wrap>//sg;      #The tables are removed to obtain a clean result section
        $PMCArticle =~ m/<\/abstract>(?:.*?)<title>Results(.*?)<title>Discussion/si;
        my $abstract=$1;
        my $ci="";

	if(defined($abstract)){
              #Transformation of data (remove percentages, special characters, currencies and p-values to gain in performance)
              $abstract=~s/9[059]\s?%//gi;
              $abstract=~s/(?:\d{1,3}(?:\.\d+)?|(?:\.\d+))\s?(?:(?:\+\/-)|pm|(?:\+-)|(?:\+\/-))\s?(?:\d{1,3}(?:\.\d+)?|(?:\.\d+))//gi;
              $abstract=~s/(\d+(?:\.\d+)?)(?:\s?(?:-|to|vs|and|,|\/)\s?(?1))*\s?%//gi;
              $abstract=~s/\*/\./gi;
              $abstract=~s/\W(?:p\s*(?:=|<=|>=|<|>|\[\?\]))(?:\s*[01](?:\.\d+)?)//gi;
              $abstract=~s/\[\?\]//gi;
              $abstract=~s/(?:\W\d+(?:,\d+)?)\s?(?:euros?|(?:(?:CAN|US|A)?(?:\$|dollars))|yens?|EUR|PS|GBP|Y=)|(?:euros?|(?:(?:CAN|US|A)?(?:\$|dollars))|yens?|EUR|PS|GBP|Y=)\s?(?:\d+(?:,\d+)?)//gi;
              $abstract=~s/((?:\d+,\d{3}(?<!\d))|(?:\d{1,4}(?:\.\d+)?|(?:\.\d+)))(?:-?)(?:(?:\s?(?:-|and|,|vs|to|\/)\s?(?1))*|-?)\s*(?:(?:tera|giga|mega|kilo|hecto|deci|centi|milli|micro|nano|pico)-?|(?:[TGMkhdcmµunp]|mu))?(?:(?:meters?|grams?|amperes?|moles?|octets?|liters?)|(?:[mMgALlo]|mol))(?:\W-?\d\W|\d\W|\W)//g;
              $abstract=~s/((?:\d+,\d{3}(?<!\d))|(?:\d{1,4}(?:\.\d+)?|(?:\.\d+)))(?:-?)(?:(?:\s?(?:-|and|,|vs|to|\/)\s?(?1))*|-?)\s*(?:(?:[dD]ays?|[mM]inutes?|[Hh]ours?|[Ss]econds?|[mM]onths?|[yY]ears?|[Aa]ngstroms?|[Bb]ars?|[Hh]ectares?|[Dd]ecibels?|[dD]egrees?|[bBecquerel]|[Gg]ray|[lL]umens?|[Ll]ux|[kK]elvin|[cC]elsius|[cC]andela)|(?:[AKCydmh°]|hrs?|mins?|mmHg|Hg|ha|dB|degs?|Gy|cd|lm|lx|Bq|[Yy]o|[Mm]o))(?:\W-?\d\W|\d\W|\W)//g;
              $abstract=~s/((?:\d+,\d{3}(?<!\d))|(?:\d{1,4}(?:\.\d+)?|(?:\.\d+)))(?:-?)(?:(?:\s?(?:-|and|,|vs|to|\/)\s?(?1))*|-?)\s*(?:(?:mega|kilo|milli|micro)-?|(?:[Mkmµu]))?(?:(?:[rR]adians?|[hH]ertz|[nN]ewtons?|[pP]ascals?|[wW]atts?|[sS]ievert|[jJ]oules?|[vV]olts?|[dD]altons?|[eE]lectron-?volts?)|(?:rads?|[Hh]z|[NJWV]|Sv|Pa|eV))(?:\W-?\d\W|\d\W|\W)//g;

              my ($once,$sig)=(0,0);
              my $orhrrr="";
              #Define if a risk can be detected inside the abstract
              my %atrisk=Load_module::identify_abs_atrisk($abstract);

              #Algorithm for ES extraction
	      while($abstract =~ m/((?:(?:(?<!un)|(?<!not)|(?<!non)|(?<!no))\W?[aA]djust)?.{0,50}?\W[aA]?)((?:[Rr]elatives?\W*[Rr]ates?)|(?:[Rr]elatives?\W*[Rr]isks?)|(?:(?:[Rr]elatives?\W*[Rr]isks?)|(?:[Hh]a[sz]ards?\W*[Rrates?])|(?:[Pp]revalences?\W*[Rrates?])|(?:[Pp]revalences?\s[Oo]dds?)|(?:[Rr]isks?)|(?:[Oo]dds?)|(?:[Hh]a[sz]ards?)|(?:[Pp]revalences?)|(?:(?:[Ii]ncidences?)?[Rr]ates?))\W*[Rr]atios?|(?:POR|por|Por|OR|IRR|irr|Irr|rrr|RRR|Rrr|hrr|HRR|HR|PRR|Prr|prr|PR|rr|RR|Rr))([sAa]?(?:djusted|crude)?\W)(.*?((?<!\d,)\d{1,3}(?:\.\d+)?|(?:\.\d+)).*?(?=\W[aA]?(?2).*)|.*(?!(?2)))/g){
                      my ($c1,$c2,$c3,$abstractpart)=(defined($1)?$1:"",defined($2)?$2:"",defined($3)?$3:"",defined($4)?$4:"");
                      my $ortemp=$c2;
                      $ortemp=~s/^[aA\s]//;
                      $ortemp=substr($ortemp,0,1);
                      if($ortemp eq "H" || $ortemp eq "h"){$orhrrr="HR";}
                      if($ortemp eq "O" || $ortemp eq "o"){$orhrrr="OR";}
                      if($ortemp eq "R" || $ortemp eq "r"){$orhrrr="RR";}
                      if($ortemp eq "I" || $ortemp eq "i"){$orhrrr="RR";}
                      if($ortemp eq "P" || $ortemp eq "p"){$orhrrr="PR";}
                      my $ortemp=$orhrrr;
                      if(substr($c3,0,1) =~ m/([as])/i){
                      		$ortemp = uc $1;
                                $ortemp=$orhrrr.$ortemp;
                      }
                      if(substr($c1,-1) =~ m/a/i){
                                $ortemp="A".$ortemp;
                      }

                      my $cx="";
                      while($abstractpart =~ m/(.*?)(?<![-\w\.])((?<!\d,)\d{1,3}(?:\.\d+)?|(?:\.\d+))([^\.\/\)\}\]\w]\D*?(?<![-\.\w<>]))((?2))([^=\+<>\.\/\)\}\]\w][^\d=\+<>]*?(?<![=\+<>\(\{\[\w]))((?2))(?![0-9]|\.[0-9])(?(?{($2<=$4||$2>=$6)})1)/g){
                              my ($c4,$c5,$c6,$c7,$c8)=(defined($2)?$2:"",defined($3)?$3:"",defined($4)?$4:"",defined($5)?$5:"",defined($6)?$6:"");
                              if(defined ($1)){$cx=$1;}

                              #Checking of the lengths of the strings
                              if(length($c5)<=100 && length($c7)<=10){
                                      my $ortemp2=uc $ortemp;
                                      my $atriskyn="";
				      if(length($c2)<=4){
                                		if(defined($atrisk{$ortemp2})){
                                                	$atriskyn=$atrisk{$ortemp2};
                                                }
                                      }
				      if((int($c4) eq "$c4") && (int($c6) eq "$c6") && (int($c8) eq "$c8")){$atriskyn="WARNING";}
                                      if(($c7 =~ m/,/ || length($cx)>200) && int($c4) eq "$c4" && int($c6) eq "$c6" && int($c8) eq "$c8"){$atriskyn="DANGER";}
                                      if(substr($c4,0,1) eq '.'){$c4='0'.$c4;}
                                      if(substr($c6,0,1) eq '.'){$c6='0'.$c6;}
                                      if(substr($c8,0,1) eq '.'){$c8='0'.$c8;}
                                      if ($c4>$c6 && $c4<$c8 && $c4>0 && $c6>0 && $c8>0 && $atriskyn ne "DANGER" && !($atriskyn eq "WARNING" && $ci eq "")){
                                              $countes++;
                                              if($once==0){$once++;}
                                              my @orbrut=($c4,$c6,$c8);
                                              print {$ini{'LSPMC'}} "$countes\t$pmid\t1\t$orbrut[0]\t$orbrut[1]\t$orbrut[2]\t$ci\t$orhrrr\tResults\n";
                                      }
                              }
                      }
              }
              if($once!=0){
              }
        }
 	close $ini{'LSPMC'};
};

#From this subroutine, random list of PMID was retrieved, giving the opportuning to the two examiners to make performance testing
any ['get', 'post'] => '/random' => sub {

    my $or = read_file($fna{'LSOR'});
    my $random = read_file($fna{'LSRD'});
    my $ct = () = $random =~ /\n/g;
    $ct--;
    my $cc=0;
    my $refrandom=retrieve($fna{'StRD'});
    my $user="User1";
    my $r =request->params;
    my %selected=("User1"=>"","User2"=>"");
    foreach my $key (keys %{$r}) {
    	if ($key eq "USER"){
        	$user=$r->{$key};
                $selected{$user}='selected';
        }
    }
    foreach my $key (keys %{$r}) {
          if ($key =~ m/PMID/){
              my $temp = $r->{$key};
              if ($temp ne ""){
                 	$refrandom->{$temp}->{$user}->{'CHECK'}='OK';
                        foreach my $key2 (keys %{$r}) {
                        	if ($key2 =~ m/(F\D)/){
                                	my $key3=$1;
                                	my $temp2 = $r->{$key2};
                                        if($key3 eq 'FP'){
                                        	$refrandom->{$temp}->{$user}->{$temp2}++;   # True positive ('TP') and False Positive ('FP')
                                        }
                                        if($key3 eq 'FN'){
                                        	if(not defined($refrandom->{$temp}->{$user}->{'FN'})){$refrandom->{$temp}->{$user}->{'FN'}=0;}  #False Negative ('FN')
                                        	$refrandom->{$temp}->{$user}->{'FN'}=$refrandom->{$temp}->{$user}->{'FN'}+$temp2;
                                        }

                                }
                        }
              }

          }
    }
    nstore \%{$refrandom}, $fna{'StRD'};

    while($random =~ m/\t(\d+)\n/g){
    	my $pmid=$1;
        $cc++;
        if(not defined($refrandom->{$pmid}->{$user}->{'CHECK'}) || (defined($refrandom->{$pmid}->{$user}->{'CHECK'}) && $refrandom->{$pmid}->{$user}->{'CHECK'} ne 'OK')){
                my $ua = new LWP::UserAgent;
                my $url = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&retmode=xml&rettype=abstract&id='.$pmid;
                my $response = $ua->get($url);
                unless ($response->is_success) {
                    die $response->status_line;
                }
                my $content = $response->decoded_content;
                $content =~ s/.*<Abstract>(.*)<\/Abstract>.*/$1/gs;

                my $temp="";
                $temp=$temp."<b>Performance testing by <input type='hidden' name='USER' value='".$user."'><input type='hidden' name='PMID' value='".$pmid."'>$user</b><table><tr><th>FN</th><th>FP</th><th>TP</th><th>Values</th></tr>";
                $temp=$temp."<tr><td><SELECT name='FN".$pmid."' size='1'><option value='0' selected>0<option value='1'>1<option value='2'>2<option value='3'>3<option value='4'>4<option value='5'>5<option value='6'>6<option value='7'>7<option value='8'>8<option value='9'>9<option value='10'>10<option value='11'>11<option value='12'>12<option value='13'>13<option value='14'>14<option value='15'>15</select></td><td></td><td></td><td>Abstract level</td><br>";
                while($or =~ m/(\d+)\t(\d+)\t$pmid\t.*?\t.*?\t([\d\.]+)\t([\d\.]+)\t([\d\.]+)\t(\D\D)\t(.*?)\t.*?\t([01])\t([01])\t([01])\t([01])\t([01])\t(.*?)\t/g){
                    $temp=$temp."<tr><td></td><td><input type='radio' name='FP".$1.$2."' value='FP'></td><td><input type='radio' name='FP".$1.$2."' value='TP' checked='checked'></td><td>$6<sub>$7CI</sub> = ".$3."[".$4.";".$5."]</td><br>";
                }
                $temp=$temp."</table><br><br><br>";
                $or=undef;
                return template 'selection', {text=>$content, es=>$temp, pmid=>$pmid, cc=>$cc, ct=>$ct, selected=>\%selected};
        }

    }

    return template 'selection';
};

#All extracted PMID were checked for the existence of a sample size (only for reviewing)
get '/extract_samplesize' => sub {
    my @pmidt;
    my %pmids;
    my $count=0;
    open(LSOR, '<', $fna{'LSOR'}) or die "Could not open file '$fna{'LSOR'}' $!";
    while( my $line = <LSOR> ) {
    	chomp($line) ;
    	$count++;
        if($count>1){
		my @sepitem=split(/\t/,$line);
                push @pmidt, $sepitem[2];
                $pmids{$sepitem[2]}{'Year'}=$sepitem[3];
                $pmids{$sepitem[2]}{'Month'}=$sepitem[4];
        }
    }
    close LSOR;
    @pmidt=List::MoreUtils::uniq(@pmidt);

    open(SSZ, '>>', $fna{'SSZ'}) or die "Could not open file '$fna{'SSZ'}' $!";
    print SSZ "pmid\tyear\tmonth\tsumsize\n";
    close SSZ;
    my $chainpmid="";
    my $total = scalar(@pmidt);
    foreach my $i (0 .. $total-1){

        $chainpmid=$pmidt[$i];
        info "$i+1/$total";
        my $echec=0;
        my $ua = new LWP::UserAgent;
        my $url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?db=pubmed&id=".$chainpmid."&retmode=xml";
        REURL:
        $echec++;
        my $response = $ua->get($url);
        unless ($response->is_success){die $response->status_line;}
        my $content = $response->decoded_content;
        $content=unidecode(decode_entities($content));

        $content=~s/9[059]\s?%//gi;
        $content=~s/(?:\d{1,3}(?:\.\d+)?|(?:\.\d+))\s?(?:(?:\+\/-)|pm|(?:\+-)|(?:\+\/-))\s?(?:\d{1,3}(?:\.\d+)?|(?:\.\d+))//gi;
        $content=~s/(\d+(?:\.\d+)?)(?:\s?(?:-|to|vs|and|,|\/)\s?(?1))*\s?%//gi;
        $content=~s/\*/\./gi;
        $content=~s/\W(?:p\s*(?:=|<=|>=|<|>|\[\?\]))(?:\s*[01](?:\.\d+)?)//gi;
        $content=~s/\[\?\]//gi;
        $content=~s/(?:\W\d+(?:,\d+)?)\s?(?:euros?|(?:(?:CAN|US|A)?(?:\$|dollars))|yens?|EUR|PS|GBP|Y=)|(?:euros?|(?:(?:CAN|US|A)?(?:\$|dollars))|yens?|EUR|PS|GBP|Y=)\s?(?:\d+(?:,\d+)?)//gi;
        $content=~s/((?:\d+,\d{3}(?<!\d))|(?:\d{1,4}(?:\.\d+)?|(?:\.\d+)))(?:-?)(?:(?:\s?(?:-|and|,|vs|to|\/)\s?(?1))*|-?)\s*(?:(?:tera|giga|mega|kilo|hecto|deci|centi|milli|micro|nano|pico)-?|(?:[TGMkhdcmµunp]|mu))?(?:(?:meters?|grams?|amperes?|moles?|octets?|liters?)|(?:[mMgALlo]|mol))(?:\W-?\d\W|\d\W|\W)//g;
        $content=~s/((?:\d+,\d{3}(?<!\d))|(?:\d{1,4}(?:\.\d+)?|(?:\.\d+)))(?:-?)(?:(?:\s?(?:-|and|,|vs|to|\/)\s?(?1))*|-?)\s*(?:(?:[dD]ays?|[mM]inutes?|[Hh]ours?|[Ss]econds?|[mM]onths?|[yY]ears?|[Aa]ngstroms?|[Bb]ars?|[Hh]ectares?|[Dd]ecibels?|[dD]egrees?|[bBecquerel]|[Gg]ray|[lL]umens?|[Ll]ux|[kK]elvin|[cC]elsius|[cC]andela)|(?:[AKCydmh°]|hrs?|mins?|mmHg|Hg|ha|dB|degs?|Gy|cd|lm|lx|Bq|[Yy]o|[Mm]o))(?:\W-?\d\W|\d\W|\W)//g;
        $content=~s/((?:\d+,\d{3}(?<!\d))|(?:\d{1,4}(?:\.\d+)?|(?:\.\d+)))(?:-?)(?:(?:\s?(?:-|and|,|vs|to|\/)\s?(?1))*|-?)\s*(?:(?:mega|kilo|milli|micro)-?|(?:[Mkmµu]))?(?:(?:[rR]adians?|[hH]ertz|[nN]ewtons?|[pP]ascals?|[wW]atts?|[sS]ievert|[jJ]oules?|[vV]olts?|[dD]altons?|[eE]lectron-?volts?)|(?:rads?|[Hh]z|[NJWV]|Sv|Pa|eV))(?:\W-?\d\W|\d\W|\W)//g;

        if($content =~ m/(\d+)<\/PMID>.*?<DateCreated>(.*?)<\/PubmedArticle>/gs){
    		my $c=$2;
                my $c1=$1;
                my $c3=0;
                my $sumsize=0;
                my $maxsize=0;
                while($c =~ m/<AbstractText Label=[^>]*?(?:method|material|study|population|participant|patient|individual|subject)[^>]+>(.*?)<\/AbstractText>/gis){
                	my $c2=$1;
                        while($c2 =~ m/(?:(?:(?:(?:n\s?=\s?)|(?:sample\w{1,20})|(?:total\w{1,20}))([1-9]+,\d{3}|\d+))|(?:([1-9]+,\d{3}|\d+)\s(?:participant|patient|individual|subject|adult|child|men|women)))/gis){
                            if(defined($1)){
                            	$c3=$1;
                                if ($c3>$maxsize){
                                	$maxsize=$c3;
                                }
                            }
                            elsif(defined($2)){
                                $c3=$2;
                            }
                            $c3=~ s/,//g;
                            $sumsize=$sumsize+$c3;
	                }
                }
                if($sumsize>0){
                	if((($maxsize+$sumsize)/$sumsize)==2){$sumsize=$sumsize/2;}
                	open(SSZ, '>>', $fna{'SSZ'}) or die "Could not open file '$fna{'SSZ'}' $!";
                	print SSZ "$c1\t$pmids{$c1}{'Year'}\t$pmids{$c1}{'Month'}\t$sumsize\n";
                        close SSZ;
                }
               	$chainpmid="";
        }
        else{
        	sleep(2);
                if($echec<10){goto REURL};
                next;
        }

    }
    return template 'index';
};

#All extracted PMID were checked for the existence of a free full text using the PubMed API, by 100
get '/check_fft' => sub {
    my @pmid;
    my $count=0;
    open(LSOR, '<', $fna{'LSOR'}) or die "Could not open file '$fna{'LSOR'}' $!";
    while( my $line = <LSOR> ) {
    	chomp($line) ;
    	$count++;
        if($count>1){
	        my @sepitem=split(/\t/,$line);
	        push @pmid, $sepitem[2];
        }
    }
    @pmid=List::MoreUtils::uniq(@pmid);
    close LSOR;

    open(FFT, '>', $fna{'LSFFT'}) or die "Could not open file '$fna{'LSFFT'}' $!";
    print FFT "pmid\n";
    my $chainpmid="";
    my $total = scalar(@pmid);
    foreach my $i (0 .. $total-1){
    	my $j=($i+1)/100;
    	if(int($j) ne "$j" && $i!=$total-1){
        	if($chainpmid eq ""){$chainpmid=$pmid[$i]."%5Buid%5D";}
                else{$chainpmid.="+OR+".$pmid[$i]."%5Buid%5D";}
        }
        else{
        	$chainpmid.="+OR+".$pmid[$i]."%5Buid%5D";
                info "$i+1/$total";
                my $ua = new LWP::UserAgent;
                my $url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?db=pubmed&term=(".$chainpmid.")+AND+loattrfree+full+text%5Bsb%5D";
                my $response = $ua->get($url);
                unless ($response->is_success){die $response->status_line;}
                my $content = $response->decoded_content;
                if($content =~ m/<Count>(\d+)<\/Count>/gs){
	                if($content !~ m/IdList\//gs){
	                    $content =~ s/^.*<IdList>\n(.*)<\/IdList>.*$/$1/gs;
	                    $content =~ s/<\/?Id>//gs;
	                    print FFT $content;
	                }
                }
                else{die "Error of communication with Pubmed";}
                $chainpmid="";
        }
    }
    close FFT;
    return template 'index';
};

#For specificity and sensitivity
get '/sensspe' => sub {

    my $refrandom=retrieve($fna{'StRD'});
    my %sensspe=('abstract'=>[0,0,0,0,0,0],'es'=>[0,0,0,0,0,0]); #Hash to store at the abstract and ES level TP, FP, FN, TN, SENS, SPE, respectively
    my %kappa=('abstract'=>[0,0,0,0,0],'es'=>[0,0,0,0,0],'temp'=>[0,0,0,0,0],'temp2'=>[0,0,0,0,0]); #Table for pp, pn,np,nn,kappa
    my %table=();
    #A for column not double checked, B for concordant, C for discordant; line 1a for true positive, 1b for true negative, 2 for false negative, 3 for false positive
    ($table{'All'},$table{'A1a'},$table{'A1b'},$table{'B1a'},$table{'B1b'},$table{'C1a'},$table{'C1b'},$table{'A2'},$table{'B2'},$table{'C2'},$table{'A3'},$table{'B3'},$table{'C3'})=("<table border=1><tr><th></th><th>Not double checked</th><th>Concordant</th><th>Discordant</th></tr>","","","","","","","","","","","","");
    delete($refrandom->{""});

    foreach my $pmid (sort keys %{$refrandom}){
    	my $tn=0;
        $kappa{'temp'}=[0,0,0,0,0];
        $kappa{'temp2'}=[0,0,0,0,0];

    	foreach my $user (sort keys %{$refrandom->{$pmid}}){
        	if(defined($refrandom->{$pmid}->{$user}->{'FP'}) && $refrandom->{$pmid}->{$user}->{'FP'}>0){
                	$sensspe{'abstract'}[1]++;
                        $sensspe{'es'}[1]+=$refrandom->{$pmid}->{$user}->{'FP'};
                        if(defined($refrandom->{$pmid}->{'User1'})&&defined($refrandom->{$pmid}->{'User2'})){$kappa{'temp'}[1]+=$user eq 'User1'?1:-1;}
                        if(defined($refrandom->{$pmid}->{'User1'})&&defined($refrandom->{$pmid}->{'User2'})){$kappa{'temp2'}[1]+=$user eq 'User1'?$sensspe{'es'}[1]:-$sensspe{'es'}[1];}
                        $tn++;
                }
                if(defined($refrandom->{$pmid}->{$user}->{'FN'}) && $refrandom->{$pmid}->{$user}->{'FN'}>0){
                	$sensspe{'abstract'}[2]++;
                        $sensspe{'es'}[2]+=$refrandom->{$pmid}->{$user}->{'FN'};
                        if(defined($refrandom->{$pmid}->{'User1'})&&defined($refrandom->{$pmid}->{'User2'})){$kappa{'temp'}[2]+=$user eq 'User1'?1:-1;}
                        if(defined($refrandom->{$pmid}->{'User1'})&&defined($refrandom->{$pmid}->{'User2'})){$kappa{'temp2'}[2]+=$user eq 'User1'?$sensspe{'es'}[2]:-$sensspe{'es'}[2];}
                        $tn++;
                }
                if(defined($refrandom->{$pmid}->{$user}->{'TP'}) && $refrandom->{$pmid}->{$user}->{'TP'}>0){
                	if($tn==0){
                        	$sensspe{'abstract'}[0]++;
                        }
                        $sensspe{'es'}[0]+=$refrandom->{$pmid}->{$user}->{'TP'};
                        if(defined($refrandom->{$pmid}->{'User1'})&&defined($refrandom->{$pmid}->{'User2'})){$kappa{'temp'}[0]+=$user eq 'User1'?1:-1;}
                        if(defined($refrandom->{$pmid}->{'User1'})&&defined($refrandom->{$pmid}->{'User2'})){$kappa{'temp2'}[0]+=$user eq 'User1'?$sensspe{'es'}[0]:-$sensspe{'es'}[0];}
                }
                else{   #For TN
                	if($tn==0){
	                        $sensspe{'abstract'}[3]++;
	                        $sensspe{'es'}[3]++;
                                if(defined($refrandom->{$pmid}->{'User1'})&&defined($refrandom->{$pmid}->{'User2'})){$kappa{'temp'}[3]+=$user eq 'User1'?1:-1;}
                                if(defined($refrandom->{$pmid}->{'User1'})&&defined($refrandom->{$pmid}->{'User2'})){$kappa{'temp2'}[3]+=$user eq 'User1'?$sensspe{'es'}[3]:-$sensspe{'es'}[3];}
                        }
                }

    	}

        if(defined($refrandom->{$pmid}->{'User1'}) && defined($refrandom->{$pmid}->{'User2'})){
                if(defined($refrandom->{$pmid}->{'User1'}->{'FP'}) && defined($refrandom->{$pmid}->{'User2'}->{'FP'})){$table{'B3'}.=$pmid.', ';}
                elsif(defined($refrandom->{$pmid}->{'User1'}->{'FN'}) && $refrandom->{$pmid}->{'User1'}->{'FN'}>0 && defined($refrandom->{$pmid}->{'User2'}->{'FN'}) && $refrandom->{$pmid}->{'User2'}->{'FN'}>0){$table{'B2'}.=$pmid.', ';}
                elsif((!defined($refrandom->{$pmid}->{'User1'}->{'FN'})||$refrandom->{$pmid}->{'User1'}->{'FN'}==0) && (!defined($refrandom->{$pmid}->{'User2'}->{'FN'})||$refrandom->{$pmid}->{'User2'}->{'FN'}==0) && !defined($refrandom->{$pmid}->{'User1'}->{'FP'}) && !defined($refrandom->{$pmid}->{'User2'}->{'FP'})){
                        if(defined($refrandom->{$pmid}->{'User1'}->{'TP'}) && $refrandom->{$pmid}->{'User1'}->{'TP'}>0 && defined($refrandom->{$pmid}->{'User2'}->{'TP'}) && $refrandom->{$pmid}->{'User2'}->{'TP'}>0){$table{'B1a'}.=$pmid.', ';}
                        else{$table{'B1b'}.=$pmid.', ';}
                }
                else{
                	if(defined($refrandom->{$pmid}->{'User1'}->{'FP'}) || defined($refrandom->{$pmid}->{'User2'}->{'FP'})){$table{'C3'}.=$pmid.', ';}
                        if((defined($refrandom->{$pmid}->{'User1'}->{'FN'})&&$refrandom->{$pmid}->{'User1'}->{'FN'}>0) || (defined($refrandom->{$pmid}->{'User2'}->{'FN'})&&$refrandom->{$pmid}->{'User2'}->{'FN'}>0)){$table{'C2'}.=$pmid.', ';}
                        if((!defined($refrandom->{$pmid}->{'User1'}->{'FN'})||$refrandom->{$pmid}->{'User1'}->{'FN'}==0) && !defined($refrandom->{$pmid}->{'User1'}->{'FP'})){
                        	if(defined($refrandom->{$pmid}->{'User1'}->{'TP'}) && $refrandom->{$pmid}->{'User1'}->{'TP'}>0){$table{'C1a'}.=$pmid.', ';}
	                        else{$table{'C1b'}.=$pmid.', ';}
                        }
                        if((!defined($refrandom->{$pmid}->{'User2'}->{'FN'})||$refrandom->{$pmid}->{'User2'}->{'FN'}==0) && !defined($refrandom->{$pmid}->{'User2'}->{'FP'})){
                        	if(defined($refrandom->{$pmid}->{'User2'}->{'TP'}) && $refrandom->{$pmid}->{'User2'}->{'TP'}>0){$table{'C1a'}.=$pmid.', ';}
	                        else{$table{'C1b'}.=$pmid.', ';}
                        }
                }
        }
        else
        {
                if(defined($refrandom->{$pmid}->{'User1'}->{'FP'}) || defined($refrandom->{$pmid}->{'User2'}->{'FP'})){$table{'A3'}.=$pmid.', ';}
                if((defined($refrandom->{$pmid}->{'User1'}->{'FN'})&&$refrandom->{$pmid}->{'User1'}->{'FN'}>0) || (defined($refrandom->{$pmid}->{'User2'}->{'FN'})&&$refrandom->{$pmid}->{'User2'}->{'FN'}>0)){$table{'A2'}.=$pmid.', ';}
                if((!defined($refrandom->{$pmid}->{'User1'}->{'FN'})||$refrandom->{$pmid}->{'User1'}->{'FN'}==0) && (!defined($refrandom->{$pmid}->{'User2'}->{'FN'})||$refrandom->{$pmid}->{'User2'}->{'FN'}==0) && !defined($refrandom->{$pmid}->{'User1'}->{'FP'}) && !defined($refrandom->{$pmid}->{'User2'}->{'FP'})){
                        if((defined($refrandom->{$pmid}->{'User1'}->{'TP'}) && $refrandom->{$pmid}->{'User1'}->{'TP'}>0)||(defined($refrandom->{$pmid}->{'User2'}->{'TP'}) && $refrandom->{$pmid}->{'User2'}->{'TP'}>0)){$table{'A1a'}.=$pmid.', ';}
                	else{$table{'A1b'}.=$pmid.', ';}
                }
        }

        if(!defined($refrandom->{$pmid}->{'User1'}) || !defined($refrandom->{$pmid}->{'User2'})){next;}

        #For TN/abstract
        if($kappa{'temp'}[3]==0){$kappa{'abstract'}[0]++;}
        elsif($kappa{'temp'}[3]==1){$kappa{'abstract'}[2]++;}
        elsif($kappa{'temp'}[3]==-1){$kappa{'abstract'}[1]++;}
        #For TP/abstract
        if($kappa{'temp'}[0]==0){$kappa{'abstract'}[0]++;}
        elsif($kappa{'temp'}[0]==1){$kappa{'abstract'}[2]++;}
        elsif($kappa{'temp'}[0]==-1){$kappa{'abstract'}[1]++;}

        #For FN/abstract
        if($kappa{'temp'}[2]==0){$kappa{'abstract'}[3]++;}
        elsif($kappa{'temp'}[2]==1){$kappa{'abstract'}[1]++;}
        elsif($kappa{'temp'}[2]==-1){$kappa{'abstract'}[2]++;}
        #For FP/abstract
        if($kappa{'temp'}[1]==0){$kappa{'abstract'}[3]++;}
        elsif($kappa{'temp'}[1]==1){$kappa{'abstract'}[1]++;}
        elsif($kappa{'temp'}[1]==-1){$kappa{'abstract'}[2]++;}

        #For TN/ES
        $kappa{'es'}[0]+=($sensspe{'es'}[3]-abs($kappa{'temp2'}[3]))/2;
        if($kappa{'temp2'}[3]>0){$kappa{'es'}[2]+=$kappa{'temp2'}[3];}
        if($kappa{'temp2'}[3]<0){$kappa{'es'}[1]+=abs($kappa{'temp2'}[3]);}
        #For TP/ES
        $kappa{'es'}[0]+=($sensspe{'es'}[0]-abs($kappa{'temp2'}[0]))/2;
        if($kappa{'temp2'}[0]>0){$kappa{'es'}[2]+=$kappa{'temp2'}[0];}
        if($kappa{'temp2'}[0]<0){$kappa{'es'}[1]+=abs($kappa{'temp2'}[0]);}

        #For FN/ES
        $kappa{'es'}[3]+=($sensspe{'es'}[2]-abs($kappa{'temp2'}[2]))/2;
        if($kappa{'temp2'}[2]>0){$kappa{'es'}[1]+=$kappa{'temp2'}[2];}
        if($kappa{'temp2'}[2]<0){$kappa{'es'}[2]+=abs($kappa{'temp2'}[2]);}
        #For FP/ES
        $kappa{'es'}[3]+=($sensspe{'es'}[1]-abs($kappa{'temp2'}[1]))/2;
        if($kappa{'temp2'}[1]>0){$kappa{'es'}[1]+=$kappa{'temp2'}[1];}
        if($kappa{'temp2'}[1]<0){$kappa{'es'}[2]+=abs($kappa{'temp2'}[1]);}

    }

    if($table{'A1a'} eq ""){$table{'A1a'}="None";}
    if($table{'B1a'} eq ""){$table{'B1a'}="None";}
    if($table{'C1a'} eq ""){$table{'C1a'}="None";}
    if($table{'A1b'} eq ""){$table{'A1b'}="None";}
    if($table{'B1b'} eq ""){$table{'B1b'}="None";}
    if($table{'C1b'} eq ""){$table{'C1b'}="None";}
    if($table{'A2'} eq ""){$table{'A2'}="None";}
    if($table{'B2'} eq ""){$table{'B2'}="None";}
    if($table{'C2'} eq ""){$table{'C2'}="None";}
    if($table{'A3'} eq ""){$table{'A3'}="None";}
    if($table{'B3'} eq ""){$table{'B3'}="None";}
    if($table{'C3'} eq ""){$table{'C3'}="None";}

    $table{'All'}.="<tr><td><b>True Positive</b></td><td>$table{'A1a'}</td><td>$table{'B1a'}</td><td>$table{'C1a'}</td></tr>";
    $table{'All'}.="<tr><td><b>True Negative</b></td><td>$table{'A1b'}</td><td>$table{'B1b'}</td><td>$table{'C1b'}</td></tr>";
    $table{'All'}.="<tr><td><b>False Negative</b></td><td>$table{'A2'}</td><td>$table{'B2'}</td><td>$table{'C2'}</td></tr>";
    $table{'All'}.="<tr><td><b>False Positive</b></td><td>$table{'A3'}</td><td>$table{'B3'}</td><td>$table{'C3'}</td></tr></table>";
    $refrandom=undef;

    if($sensspe{'abstract'}[0]>0){$sensspe{'abstract'}[4]=sprintf("%.2f",$sensspe{'abstract'}[0]/($sensspe{'abstract'}[0]+$sensspe{'abstract'}[2])*100).'%';}  #Sensibility TP/(TP+FN)
    else{$sensspe{'abstract'}[4]="Not applicable";}
    if($sensspe{'abstract'}[3]>0){$sensspe{'abstract'}[5]=sprintf("%.2f",$sensspe{'abstract'}[3]/($sensspe{'abstract'}[3]+$sensspe{'abstract'}[1])*100).'%';}  #Specificity TN/(TN+FP)
    else{$sensspe{'abstract'}[5]="Not applicable";}
    if($sensspe{'es'}[0]>0){$sensspe{'es'}[4]=sprintf("%.2f",$sensspe{'es'}[0]/($sensspe{'es'}[0]+$sensspe{'es'}[2])*100).'%';}  #Sensibility TP/(TP+FN)
    else{$sensspe{'es'}[0]="Not applicable";}
    if($sensspe{'es'}[3]>0){$sensspe{'es'}[5]=sprintf("%.2f",$sensspe{'es'}[3]/($sensspe{'es'}[3]+$sensspe{'es'}[1])*100).'%';}  #Specificity TN/(TN+FP)
    else{$sensspe{'es'}[5]="Not applicable";}

    $kappa{'abstract'}[4]=nearest(.01,2*($kappa{'abstract'}[0]*$kappa{'abstract'}[3]-$kappa{'abstract'}[1]*$kappa{'abstract'}[2])/(($kappa{'abstract'}[0]+$kappa{'abstract'}[1])*($kappa{'abstract'}[1]+$kappa{'abstract'}[3])+($kappa{'abstract'}[2]+$kappa{'abstract'}[3])*($kappa{'abstract'}[0]+$kappa{'abstract'}[2])));
    $kappa{'es'}[4]=nearest(.01,2*($kappa{'es'}[0]*$kappa{'es'}[3]-$kappa{'es'}[1]*$kappa{'es'}[2])/(($kappa{'es'}[0]+$kappa{'es'}[1])*($kappa{'es'}[1]+$kappa{'es'}[3])+($kappa{'es'}[2]+$kappa{'es'}[3])*($kappa{'es'}[0]+$kappa{'es'}[2])));

    my($colorab,$nameab,$colores,$namees)=('','','Not computed','Not computed');
    if($kappa{'abstract'}[4]>=0.8){($colorab,$nameab)=('SeaGreen','Excellent');}
    elsif($kappa{'abstract'}[4]>=0.6){($colorab,$nameab)=('LightSkyBlue','Good');}
    elsif($kappa{'abstract'}[4]>=0.4){($colorab,$nameab)=('Yellow','Moderate');}
    elsif($kappa{'abstract'}[4]>=0.2){($colorab,$nameab)=('Orange','Poor');}
    elsif($kappa{'abstract'}[4]>=0){($colorab,$nameab)=('Red','Bad');}
    elsif($kappa{'abstract'}[4]<0){($colorab,$nameab)=('MediumVioletRed','Very bad');}

    ($colores,$namees)=('','Not computed');
    if($kappa{'es'}[4]>=0.8){($colores,$namees)=('SeaGreen','Excellent');}
    elsif($kappa{'es'}[4]>=0.6){($colores,$namees)=('LightSkyBlue','Good');}
    elsif($kappa{'es'}[4]>=0.4){($colores,$namees)=('Yellow','Moderate');}
    elsif($kappa{'es'}[4]>=0.2){($colores,$namees)=('Orange','Poor');}
    elsif($kappa{'es'}[4]>=0){($colores,$namees)=('Red','Bad');}
    elsif($kappa{'es'}[4]<0){($colores,$namees)=('MediumVioletRed','Very bad');}

    my $time=localtime;
    return template 'kappa', {gmtime=>$time,table=> $table{'All'},kappaab=>$kappa{'abstract'}[4],kappaes=>$kappa{'es'}[4],colores=>$colores,namees=>$namees,colorab=>$colorab,nameab=>$nameab,sensab=>$sensspe{'abstract'}[4],senses=>$sensspe{'es'}[4],speab=>$sensspe{'abstract'}[5],spees=>$sensspe{'es'}[5]};

};

true;