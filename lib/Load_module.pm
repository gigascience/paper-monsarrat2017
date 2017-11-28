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

package Load_module;
use strict;
use Dancer ':syntax';
use Storable;
use Data::Dumper;
use File::Slurp;

my %fna=('MAPA'=>'PubMedFiles/Mapaffil/mapaffil2015.tsv','LSOR'=>'listOR.txt','LSCO2'=>'listOR_countries2.txt');

#Identify abstracts with risks
sub identify_abs_atrisk{
	my $abstract=$_[0];
        my %atrisk=();
        ($atrisk{"AHRS"},$atrisk{"AHR"},$atrisk{"HRS"},$atrisk{"HR"},$atrisk{"HRA"},$atrisk{"HRS"},$atrisk{"IRRS"},$atrisk{"IRR"},$atrisk{"IRRA"},$atrisk{"ARR"},$atrisk{"ARRS"},$atrisk{"RRA"},$atrisk{"RRAS"},$atrisk{"RRS"},$atrisk{"RR"},$atrisk{"AOR"},$atrisk{"AORS"},$atrisk{"PRRS"},$atrisk{"PRR"},$atrisk{"PRA"},$atrisk{"PR"},$atrisk{"PRS"},$atrisk{"POR"},$atrisk{"PORS"},$atrisk{"PORA"},$atrisk{"APOR"},$atrisk{"APORS"},$atrisk{"APRS"},$atrisk{"APR"},$atrisk{"ORS"},$atrisk{"OR"},$atrisk{"ORA"},$atrisk{"ORAS"})=("OK","OK","OK","OK","OK","OK","OK","OK","OK","OK","OK","OK","OK","OK","OK","OK","OK","OK","OK","OK","OK","OK","OK","OK","OK","OK","OK","OK","OK","OK","OK","OK","OK");

        #OR type
        #For the PORS sentence
        if($abstract =~ m/Patients?.?Oriented\WResearches\W|Physicians?\WOf\WRecords\W|Porfiro.?mycins\W|Porins\W|Portions\W|Post.?occlusives\WOscillatory\WResponses\W|Post.?occlusives?\WReductions\W|Post.?rhinals?\WCortex\W|Problems?.?Oriented\WRecords\W|Proto.?chloro.?phyllides\WOxido.?reductases\W|Proto.?chlorophyllides?\WReductases\W|Pyruvate.?Ferredoxin.?Oxido.?reductases\W|Pyruvate.?Oxido.?reductases\W|Probabilit(?:y|ies)\WOf\WRemissions\W|Porphyrins\W/i){$atrisk{"PORS"}="WARNING";}
        #For the POR sentence
        if($abstract =~ m/Patients?.?Oriented\WResearch(?:es)?\W|Physicians?\WOf\WRecords?\W|Porfiro.?mycins?\W|Porins?\W|Portally\W|Portions?\W|Post.?occlusives?\WOscillatory\WResponses?\W|Post.?occlusives?\WReductions?\W|Post.?rhinals?\WCortex\W|Problems?.?Oriented\WRecords?\W|Proto.?chloro.?phyllides?\WOxido.?reductases?\W|Proto.?chlorophyllides?\WReductases?\W|Pyruvate.?Ferredoxin.?Oxido.?reductases?\W|Pyruvate.?Oxido.?reductases?\W|Probabilit(?:y|ies)\WOf\WRemissions?\W|Porphyrins?\W/i){$atrisk{"POR"}="WARNING";}
        if($abstract =~ m/Problems?.?Oriented.?Records?.{0,15}Systems\W|Proportionals?\WOperations?\WRatios\W|Psychiatrics?\WOutpatients?\WRatings?\WScales?\W/i){$atrisk{"PORS"}="WARNING";}
        #For the PORA sentence
        if($abstract =~ m/Porins?.?A\W/i){$atrisk{"PORA"}="WARNING";}
        #For the APOR sentence
        if($abstract =~ m/Apo.?lipo.?proteins?\WR\W|Apoptosis.?Resistants?\W|Appendiceals?\WOrifices?\W|Associations?\W.{0,6}Patients?\WOriented.?Research(?:es)?/i){
        	$atrisk{"APOR"}="WARNING";
                $atrisk{"APORS"}="WARNING";
        }
        #For the APRS sentence
        if($abstract =~ m/Abdomino.?perineals?\WResections\W|Absolutes?\WProductions?\WRates\W|Absolutes?\WProximals?\WReabsorptions\W|Accessory\WPlanta\WRetractors\W|Acutes?\WPhases?\W(?:Reactants|Reactions|Responses)\W|Advances?\WProductions?\WReleases\W|Amebics?\WPrevalences?\WRates\W|Anatomics?\WPorous\WReplacements\W|Anteriors?\WPituitary\WReactions\W|Aprotinins\W|Automatics?\WPressures?\WReliefs\W|Ampicillins?\WResistan.{1,5}s\W|Acutes?\WPains?\WReliefs?\WServices?\W|Acutes?\WPsychiatrics?\WRatings?\WScales?\W|Acutes?.?Phases?\WRabbits?\W(?:Serum|Sera)\W|Allelics?\WPolymorphics?\WRegions?\W|Automatisms?\W.{0,10}Preserved\WResponsiveness/i){$atrisk{"APRS"}="WARNING";}
        #For the APR sentence
        if($abstract =~ m/Abdomino.?perineals?\WResections?\W|Absolutes?\WProductions?\WRates?\W|Absolutes?\WProximals?\WReabsorptions?\W|Accessory\WPlanta\WRetractors?\W|Acutes?\WPhases?\W(?:Reactants?|Reactions?|Responses?)\W|Advances?\WProductions?\WReleases?\W|Amebics?\WPrevalences?\WRates?\W|Anatomics?\WPorous\WReplacements?\W|Anteriors?\WPituitary\WReactions?\W|Aprotinins?\W|Automatics?\WPressures?\WReliefs?\W|Ampicillins?\WResistan/i){$atrisk{"APR"}="WARNING";}
        #For the PRS sentence
        if($abstract =~ m/per.?recta\W|Pulses?\WRates\W|Pagetoides?\WRetikuloses\W|Palindromics?\WRheumatisms\W|Parallax.{0,6}Refractions\W|Partials?\WReinforcements\W|Partials?\WRemissions\W|Partials?\WResponses\W|Partials?\WResponders\W|Particulars?\WRespirators\W|Peers?\WReviews\W|Penrose.?Drains\W|Perfusions?\WRates\W|Peripherals?\WResistances\W|Pesticides?\WRegulations\WPhenol.?Reds\W|Photo.?reactions\W|Physicals?\WRehabilitations\W|Polyarthrites?\WRhumato.des\W|Posteriors?\WRoots\W|Posturals?\WReflexes\W|(?:Potency|Potencies)\WRatios\W|Precipitations?\WRadars\W|Preferences?\WRecords\W|(?:Pregnancy|Pregnancies)\WRates\W|Pre.?retinals?\W|Presso.?receptors\W|Pressures\W|Pregnancies\W|Preyer\WReflexes\W|Proctologies\W|Productions?\WRates\W|Profiles\W|Progesterones?\WReceptors\W|Progress(?:es)\WReports\W|Progressives?\WRelaxations\W|Progressives?\WResistances\W|Prolactins\W|Prolonged.?Remissions\W|Prospectives?\WReimbursements\W|Proteins\W|Publics?.?Relations\W|(?:Pulmonary|Pulmonaries)\WRehabilitations\W|Pulmonics?\WRegurgitations\W|Pulses?\WRepetitions\W|Pyramidals?\WResponses\W|Prednisolones|Pairs\W/i){$atrisk{"PRS"}="WARNING";}
        #For the PR sentence
        if($abstract =~ m/per.?rectum\W|Pulses?\WRates?\W|Pagetoides?\WRetikuloses?\W|Palindromics?\WRheumatisms?\W|Parallax.{0,6}Refractions?\W|Partials?\WReinforcements?\W|Partials?\WRemissions?\W|Partials?\WResponses?\W|Partials?\WResponders?\W|Particulars?\WRespirators?\W|Peers?\WReviews?\W|Penrose.?Drains?\W|Perfusions?\WRates?\W|Peripherals?\WResistances?\W|Pesticides?\WRegulations?\W|Phenol.?Red\W|Photo.?reactions?\W|Physicals?\WRehabilitations?\W|Pityriasis.?Rosea\W|Polyarthrites?\WRhumato.des?\W|Posteriors?\WRoots?\W|Postmyalgia\WRheumatica\W|Posturals?\W(?:Reflex|Reflexes)\W|(?:Potency|Potencies)\WRatios?\W|Precipitations?\WRadars?\W|Preferences?\WRecords?\W|(?:Pregnancy|Pregnancies)\WRates?\W|Pre.?retinals?\W|Presso.?receptors?\W|Pressures?\W|Pregnancy\W|Pregnancies\W|Preyer\W(?:Reflex|Reflexes)\W|Proctology\W|Proctologies\W|Productions?\WRates?\W|Profiles?\W|Progesterones?\WReceptors?\W|Progress(?:es)\WReports?\W|Progressives?\WRelaxations?\W|Progressives?\WResistances?\W|Prolactins?\W|Proline.?Rich|Prolonged.?Remissions?\W|Propranolol|Prospectives?\WReimbursements?\W|Prosthion|Proteins?\W|Publics?.?Relations?\W|(?:Pulmonary|Pulmonaries)\WRehabilitations?\W|Pulmonics?\WRegurgitations?\W|Pulses?\WRepetitions?\W|Pyramidals?\WResponses?\W|Praseodymium|Prednisolones?|Presbyopia|Prism|Propyl|Pairs?\W/i){$atrisk{"PR"}="WARNING";}
        if($abstract =~ m/Parry.?Romberg.?Syndromes?\W|Plasmas?\WRenins?\WSubstrates?\W|Personality.?Ratings?.?\WScales?|Pharmaceuticals?\WReimbursements?\WSections?\W|Phospho.?ribosyl.?pyrophosphates?\WSynthetases?\W|Photon.?\WRadiosurgery\WSystems?\W|Pierre.?Robin.?Syndromes?\W|Post.?radiations?\WSarcoma.?\W|Post.?reperfusions?\WSyndromes?\W|Post.?ribosomals?\WSupernatants?\W|Pressures?\W|Preventions?\WResearch.{1,4}Synthes.s\W|Procto.?recto.?sigmoidoscop|Producers?\WRetailers\W|P.?Receptors\W|Pharmaceuticals?\WRepresentatives\W|Photo.?receptors|Primitives?\WReflexes\W|Progestins?\WReceptors\W|Proteases\W/i){$atrisk{"PRS"}="WARNING";}
        #For the PRA sentence
        if($abstract =~ m/Panels?.?Reactives?.?Antibod|Paperworks?\WReductions?\WActs?\W|Participatory.?Rurals?.?Appraisals?\W|PCR.?Restriction|Peripherals?.?Renins?.?Activit|Pharmacy.?Restructuring.?Authorit|Phospho.?ribosyl.?amine|Physicians?\WRecognitions?\WAwards?\W|Plaques?.?Reductions?\WAssay|Plasma.{1,30}Renins?\WActivit|Polymorphisms?\WAnalys|Positives?\WRelatives?\WAccommodations?\W|Prazosin|Pre.?Renals?\WAzotemia|Probabilistic.?Risks?\WAnalys|Progesterone.?Receptors?\WAssay|Progressives?\WRetinals?\WAtroph/i){$atrisk{"PRA"}="WARNING";}
        #For the PRRS sentence
        if($abstract =~ m/Pathogens?\WRecognising\WReceptors\W|Plasma\WRefilling\WRates\W|Plasma\WRenins?\WReactivities\W|Platelets?\WRetentions?\WRates\W|Poliovirus\WReceptors?\WRelated\W|Post.?radiations?\WRecurrences\W|Post.?replication.{1,6}Repairs\W|Post.?repolarizations\WRefractorinesses|Pre.?Readiness.?Reviews\W|Progesterones?\WReceptors\W|Proline.?Rich.?Regions\W|Proline.?Rich.?Repeats\W|Promoters?\WRecognitions?\WRegions\W|Proportionals?\WReportings?\WRatios\W|Protectives?\WResponses?\WRecommendations\W|Protons?\WRelaxations?\WRates\W|Proximals?\WRegulator(?:y|ies)\WRegions\W|Pulmonar(?:y|ies)\WReimplantations?\WResponses\W|Pulses?\WRepetitions?\WRates\W/i){$atrisk{"PRRS"}="WARNING";}
        if($abstract =~ m/Porcines?\WReproductive.{1,10}Respirator(?:y|ies)\WSyndromes?|Porcines?\WRespirator(?:y|ies).{1,10}Reproductive\WSyndromes?|Positives?.?Regulator(?:y|ies)\WRegions?\W|Prolines?.?Rich.{1,15}Sequences?\W|Psychomotors?\WRetardations?\WRatings?\WScales?\W/i){$atrisk{"PRRS"}="WARNING";}
        #For the PRR sentence
        if($abstract =~ m/Pathogens?\WRecognising\WReceptors?\W|Plasma\WRefilling\WRates?\W|Plasma\WRenins?\WReactivit(?:y|ies)\W|Platelets?\WRetentions?\WRates?\W|Poliovirus\WReceptors?\WRelated\W|Post.?radiations?\WRecurrences?\W|Post.?replication.{1,6}Repairs?\W|Post.?repolarizations?\WRefractoriness|Pre.?Readiness.?Reviews?\W|Progesterones?\WReceptors?\W|Proline.?Rich.?Regions?\W|Proline.?Rich.?Repeats?\W|Promoters?\WRecognitions?\WRegions?\W|Proportionals?\WReportings?\WRatios?\W|Protectives?\WResponses?\WRecommendations?\W|Protons?\WRelaxations?\WRates?\W|Proximals?\WRegulator(?:y|ies)\WRegions?\W|Pulmonar(?:y|ies)\WReimplantations?\WResponses?\W|Pulses?\WRepetitions?\WRates?\W/i){$atrisk{"PRR"}="WARNING";}
        #For the ORS sentence
        if($abstract =~ m/Oculo.?Respiratory\WSyndromes?\W|Oculo.?Respiratories\WSyndromes?\W|Olfactory\WReferences?\WSyndromes?\W|Olfactories\WReferences?\WSyndromes?\W|Orals?\WRehydrations?\WSalts?\W|Orals?\WRehydrations?\WSolutions?\W|Orals?\WSurgerys?\W|Orals?\WSurgeons?\W|Origins?.?Enricheds?.?Sequences?\W|Orthopaedics?\WResearchs?\WSociety\W|Orthopaedics?\WResearchs?\WSocieties\W|Orthopedics?\WSurgeons?\W|Orthopedics?\WSurgeries\W|Outers?\WRoots?\WSheaths?\W|Oxygens?\WRadicals?\WScavengers?\W|Objectives?\WRemissions?\W|Objectives?\WResponses?\W|Odorant Receptors?\W|Oestrogens?\WReceptors?\W|Olfactory\WReceptors?\W|Operatings?\WRooms?\W|Opioids?\WReceptors?\W|Organs?\WAts?\WRisks?\W|Orientings?\WResponses?\W/i){$atrisk{"ORS"}="WARNING";}
        #For the OR sentence
        if($abstract =~ m/Ovulations?\WRates?\W|Oils?\WRetentions?\W|Opens?\WReductions?\W|Operatings?\WRooms?\W|Operations?\WResearchs?\W|Optics?\WRadiations?\W|Orals?\WRehydrations?\W|Oroso.?mucoids?\W|Orthopedics?\WResearchs?\W|Outcomes?\WResearchs?\W|Rates?\Wof\WOutflows?\W|Outflows?\WRates?\W|Orbitales?\W|Oestrogens?\WReceptors?\W/i){$atrisk{"OR"}="WARNING";}
        if($abstract =~ m/Ovulations?\WRates\W|Oils?\WRetentions\W|Opens?\WReductions\W|Operatings?\WRooms\W|Operations?\WResearchs\W|Optics?\WRadiations\W|Orals?\WRehydrations\W|Oroso.?mucoids\W|Orthopedics?\WResearchs\W|Outcomes?\WResearchs\W|Rates?\Wof\WOutflows\W|Outflows?\WRates\W|Orbitales?\W|Oestrogens?\WReceptors\W/i){$atrisk{"ORS"}="WARNING";}
        #For the ORA sentence
        if($abstract =~ m/Opioids?\WReceptors?\WAgonists?\W|Oculars?\WResiduals?\WAstigmatisms?\W|Offices?\Wof\WRegulatory\WAffairs?\W|Offices?\Wof\WRegulatories\WAffairs?\W|Opiates?\WReceptors?\WAgonists?\W|Opioids?\WReceptors?\WAgonists?\W|Opposites?\WRays?\WAlgorithms?\W|Opticals?\WRapids?\WAssays?\W|Outwardly\WRectifyings?\WAstrocytes?\W|Oxidoreductases?\WActivity|Oxidoreductases?\WActivities\W/i){$atrisk{"ORA"}="WARNING";}
        #For the ORAS sentence
        if($abstract =~ m/Opioids?\WReceptors?\WAgonists\W|Oculars?\WResiduals?\WAstigmatisms\W|Offices?\Wof\WRegulatory\WAffairs\W|Offices?\Wof\WRegulatories\WAffairs\W|Opiates?\WReceptors?\WAgonists\W|Opioids?\WReceptors?\WAgonists\W|Opposites?\WRays?\WAlgorithms\W|Opticals?\WRapids?\WAssays\W|Outwardly\WRectifyings?\WAstrocytes\W|Oxidoreductases?\WActivities\W/i){$atrisk{"ORAS"}="WARNING";}
        #For the AOR sentence
        if($abstract =~ m/Acridines?\WOranges?\WReactions?\W|Adequates?\WOvarians?\WReserves?\W|Aldehydes?\WFerredoxins?\WOxido.?reductases?\W|Aldehydes?\WOxidoreductases?\W|Alvarados?\WOrthopedics?\WResearche?s?\W|Aortas?\W|Aortics?\WRoots?\W|AtOwns?\WRisks?\W|Audio.?Oculars?\WResponses?\W|Auditory.?Oculogyric\WReflex\W|Auditories.?Oculogyric\WReflexes\W|Occlusions?\Wand\WReperfusions?\W|Adult.?.?Onset.?Rheumatoids?\WArthritis\W|Onset.?Rheumatoids?\WArthritis\W/i){$atrisk{"AOR"}="WARNING";}
        if($abstract =~ m/Acridines?\WOranges?\WReactions\W|Adequates?\WOvarians?\WReserves\W|Aldehydes?\WFerredoxins?\WOxido.?reductases\W|Aldehydes?\WOxidoreductases\W|Alvarados?\WOrthopedics?\WResearche?s\W|Aortas?\W|Aortics?\WRoots\W|AtOwns?\WRisks\W|Audio.?Oculars?\WResponses\W|Auditories.?Oculogyric\WReflexes\W|Occlusions?\Wand\WReperfusions\W|Adult.?.?Onset.?Rheumatoids?\WArthritis\W|Onset.?Rheumatoids?\WArthritis\W/i){$atrisk{"AORS"}="WARNING";}

        #RR type
        #For the RRS sentence
        if($abstract =~ m/Respirations?\WRates\W|Radiations?\WResearchs?\WSociety\W|Raman\WSpectroscopy\W|Ras\W?Recruitments?\WSystems?\W|Recovery\WOf\WRNA\WSynthesis\W|Rep\WRecognitions?\WSequences?\W|Resonances?\WRaman\WScattering\W|Resonances?\WRayleigh\WScattering\W|Retro\W?rectals?\WSpaces?\W|Richards?\WRundles?\WSyndromes?\W|Recruiting\WResponses?\W|Resistances?\WRatios?\W|Respiratory\WRates?\W|Respiratories\WRates?\W|Responses?\WRates?\W|Respiratory\WResistances?\W|Respiratories\WResistances?\W|Respiratory\WSystems?\W|Respiratories\WSystems?\W/i){$atrisk{"RRS"}="WARNING";}
        #For the RR sentence
        if($abstract =~ m/Respirations?\WRates?\W|resonances?\Wramans?\W|Radiations?\WReactions?\W|Radiations?\WResponses?\W|Rationals?\WRecovery\W|Rationals?\WRecoveries\W|Recoveries\WRooms?\W|Recovery\WRooms?\W|Reflejo.?Rotulianos?\W|Relatives?\WResponses?\W|Renins?\WReleases?\W|Respiratory\Wrates?\W|Respiratory\WReserves?\W|Respiratories\Wrates?\W|Respiratories\WReserves?\W|Responses?\WRates?\W|Results?\WReportings?\W|Retinals?\WReflux\W|Retinals?\WRefluxes\W|Rheumatoids?\WRosettes?\W|Ribonucleotides?\WReductases?\W|Riva.?Rocci\W/i){$atrisk{"RR"}="WARNING";}
        if($abstract =~ m/Radiations?\WReactions\W|Radiations?\WResponses\W|Rationals?\WRecoveries\W|Recoveries\WRooms\W|Recovery\WRooms\W|Reflejo.?Rotulianos\W|Relatives?\WResponses\W|Renins?\WReleases\W|Respiratory\Wrates\W|Respiratory\WReserves\W|Respiratories\Wrates\W|Respiratories\WReserves\W|Responses?\WRates\W|Results?\WReportings\W|Retinals?\WRefluxes\W|Rheumatoids?\WRosettes\W|Ribonucleotides?\WReductases\W/i){$atrisk{"RRS"}="WARNING";}
        #For the RRA sentence
        if($abstract =~ m/Radio.?active.?Iodine\W|Remnants?\WAblations?\W|Radio.?iodine.?Remnants?\WAblations?\W|Radioligand.?Receptors?.?Assays?\W|Rights?\WRadials?\WArtery\W|Rights?\WRenals?\WArtery\W|Rights?\WRadials?\WArteries?\W|Rights?\WRenals?\WArteries?\W|Rurals?\WAppraisals?\W|Radio.?receptors?\WActivity\W|Radio.?receptors?\WAnalysis\W|Radio.?receptors?\WActivities\W|Radio.?receptors?\WAnalyses\W|Radio.?receptors?\WAssays?\W|Radio.?receptors?.?Bindings?\WAssays?\W|Retro.?rubrals?\WAreas?\W|Reactions?\WRates?\WAnalysers?\W|Receptors?\WRadioligands?\WAssays?\W|Receptorassays?\WAnalysis\W|Receptorassays?\WAnalyses\W|Receptors?\WRadioreceptors?\WAssays?\W|Registered\WRecords?\WAdministrators?\W|Registered\WRestoratives?\WAssistants?\W|Renals?\W.{0,10}Renin\WActivity\W|Renals?\W.{0,10}Renin\WActivities\W/i){$atrisk{"RRA"}="WARNING";}
        if($abstract =~ m/Remnants?\WAblations\W|Radio.?iodine.?Remnants?\WAblations\W|Radioligand.?Receptors?.?Assays\W|Rights?\WRadials?\WArteries\W|Rights?\WRenals?\WArteries\W|Rurals?\WAppraisals\W|Radio.?receptors?\WActivities\W|Radio.?receptors?\WAnalyses\W|Radio.?receptors?\WAssays\W|Radio.?receptors?.?Bindings?\WAssays\W|Retro.?rubrals?\WAreas\W|Reactions?\WRates?\WAnalysers\W|Receptors?\WRadioligands?\WAssays\W|Receptorassays?\WAnalyses\W|Receptors?\WRadioreceptors?\WAssays\W|Registered\WRecords?\WAdministrators\W|Registered\WRestoratives?\WAssistants\W|Renals?\W.{0,10}Renin\WActivities\W/i){$atrisk{"RRAS"}="WARNING";}
        #For the ARR sentence
        if($abstract =~ m/Absolutes?\WRisks?\WReductions?\W|Acceleratings?\WRotarods?\W|Achievables?\WRisks?\WReductions?\W|Acutes?\WReactions?\W.{0,4}Rejections?\W|Age.{0,3}Related\WResistances?\W|Airways?\WRetentions?\WRatios?\W|Aldosterones?\W.{0,4}Plasmas?\WRenins?\W|Aldosterone.{0,10}Renins?\WRatios?\W|Antigens?\WRetaining\WReticulum\W|Aortics?\Wroots?\Wreplacements?\W|Arrhythmia\W|Arrestin\W|Arsenates?\WReductases?\W/i){$atrisk{"ARR"}="WARNING";}
        if($abstract =~ m/Absolutes?\WRisks?\WReductions\W|Acceleratings?\WRotarods\W|Achievables?\WRisks?\WReductions\W|Acutes?\WReactions?\W.{0,4}Rejections\W|Age.{0,3}Related\WResistances\W|Airways?\WRetentions?\WRatios\W|Aldosterones?\W.{0,4}Plasmas?\WRenins\W|Aldosterone.{0,10}Renins?\WRatios\W|Aortics?\Wroots?\Wreplacements\W|Arsenates?\WReductases\W/i){$atrisk{"ARRS"}="WARNING";}
        #For the IRRS sentence
        if($abstract =~ m/Insulins?\W(?:Receptors?\W|Related\W)|(?:Related\W|Receptors?\W)|inter.?raters?\Wreliabilities\W|Increased\WRadioresistances\W|Induced\WRadioresistances\W|Insulin\WReceptors\WRelated\WReceptors\W|Internals?\WRates?.{1,4}Returns\W|Internationals?\WReferences?\WReagents\W|Intra.?renal.?\WReflux\W|Inverted\WRepeats\W|Ionising\WRadiations?\WRegulations\W|Iron\WResponses?\WRegulators\W/i){$atrisk{"IRRS"}="WARNING";}
        if($abstract =~ m/Inspiratory\WRrs|Inspiratories\WRrs|Interleaved\W(?:Acquisition)?.{1,4}Relaxations?\WRecovery\WSpaces?\W/i){$atrisk{"IRRS"}="WARNING";}
        #For the IRR sentence
        if($abstract =~ m/inter.?raters?\Wreliability\W|inter.?raters?\Wreliabilities\W|Increased\WRadioresistances?\W|Induced\WRadioresistances?\W|Insulin\WReceptors?\WRelated\WReceptors?\W|Internals?\WRates?.{1,4}Returns?\W|Internationals?\WReferences?\WReagents?\W|Intra.?renal.?\WReflux\W|Inverted\WRepeats?\W|Ionising\WRadiations?\WRegulations?\W|Iron\WResponses?\WRegulators?\W/i){$atrisk{"IRR"}="WARNING";}
        #For the IRRA sentence
        if($abstract =~ m/Infrared\WReflections?\WAbsorptions?\W|Isolated\WRubbed\WRats?\WAortas?\W/i){$atrisk{"IRRA"}="WARNING";}

        #HR type
        #For the HRS sentence
        if($abstract =~ m/Hamman\W?Rich\Wsyndromes?\W|Hamilton\WRating\WScales?\W|Hazard Ranking Systems?\W|Health and Rehabilitative Services?\W|Health.{0,5}Retirement\WStudy\W|Health.{0,5}Retirement\WStudies\W|Hepatorenals?\WSyndromes?\W|High.{0,4}Rate.{0,6}Stimulations?\W|Histidyl.?T.?rna.?Synthetases?\W|Hodgkin.{0,5}Reed.?Sternberg\W|Hormones?.Receptors?\WSites?\W|Humeroradials?\WSynostosis\W|Humeroradials?\WSynostoses\W|Hyper.?Radio.?sensitivity|Hyper.?Radio.?sensitivities/i){$atrisk{"HRS"}="WARNING";}
    	#For the HR sentence
        if($abstract =~ m/Hallux\WRigidus\W|Hamman\W?Rich\W|Hearts?\Wrates?\W|Heatings?\Wrates?\W|Hematologics?\WResponses?\W|Hemi.?rectococcygeus\W|Hemorrhagics?\WRetinopathy\W|Hemorrhagics?\WRetinopathies\W|Heterosexuals?\WRelations?\W|Highs?\WResolutions?\W|Highs?.?Risks?\W|Highers?\WRates?\W|Histamines?\WReceptors?\W|Hormonals?\WResponses?\W|Hospitals?\WRecords?\W|Hospitals?\WReports?\W|Howship.?Romberg.?Syndromes?\W|Humans?\WResources?\W|Hydroxy.?ethyl.?rutinosides?\W|Hyper.?immunes?.?Reactions?\W|Hypophosphatemics?\WRickets?\W|Hypoxics?\WResponders?\W|Hair.?less|Hosts?\WRanges?\W|Humans?\WRecombinants?\W|Hearts?\WReactives?\W|Homologous\WRegions?\W/i){$atrisk{"HR"}="WARNING";}
        if($abstract =~ m/Hallux\WRigidus\W|Hearts?\Wrates\W|Heatings?\Wrates\W|Hematologics?\WResponses\W|Hemi.?rectococcygeus\W|Hemorrhagics?\WRetinopathies\W|Heterosexuals?\WRelations\W|Highs?\WResolutions\W|Highs?.?Risks\W|Highers?\WRates\W|Histamines?\WReceptors\W|Hormonals?\WResponses\W|Hospitals?\WRecords\W|Hospitals?\WReports\W|Howship.?Romberg.?Syndromes\W|Humans?\WResources\W|Hydroxy.?ethyl.?rutinosides\W|Hyper.?immunes?.?Reactions\W|Hypophosphatemics?\WRickets\W|Hypoxics?\WResponders\W|Hosts?\WRanges\W|Humans?\WRecombinants\W|Hearts?\WReactives\W|Homologous\WRegions\W/i){$atrisk{"HRS"}="WARNING";}
        #For the AHR sentence
        if($abstract =~ m/Abacavir.?Hypersensitivity.?Reactions?\W|Acutes?\WHumorals?\WRejections?\W|Airways?\WHyperreactivity\W|Airways?\WHyperreactivities\W|Airways?\WHyper.?responsiveness\W|Alcohol.?based.?Hands?.?Rubs?\W|Anti.?hyaluronidases?\Wreactions?\W|Aqueous.?Homogeneous.?Reactors?\W|Assisted.?Humans?.?Reproductions?\W|Association.{0,5}healths?\Wrecords?\W|Atrials?\Whearts?\Wrates?\W|A.?h.?Receptors?\W|Aromatics?\WHydrocarbons?\WReceptors?\W|Aryl.?Hydrocarbons?\WReceptors?\W|Armys?\WHumans?\WResources?\W/i){$atrisk{"AHR"}="WARNING";}
        if($abstract =~ m/Abacavir.?Hypersensitivity.?Reactions\W|Acutes?\WHumorals?\WRejections\W|Airways?\WHyperreactivities\W|Alcohol.?based.?Hands?.?Rubs\W|Anti.?hyaluronidases?\Wreactions\W|Aqueous.?Homogeneous.?Reactors\W|Assisted.?Humans?.?Reproductions\W|Association.{0,5}healths?\Wrecords\W|Atrials?\Whearts?\Wrates\W|A.?h.?Receptors\W|Aromatics?\WHydrocarbons?\WReceptors\W|Aryl.?Hydrocarbons?\WReceptors\W|Armys?\WHumans?\WResources\W|Army\sHumans?\WResources?\WStrategy\W|Army\sHumans?\WResources?\WStrategies\W/i){$atrisk{"AHRS"}="WARNING";}
        #For the HRA sentence
        if($abstract =~ m/Humans?\WRecombinants?\WAfgfs?\W|Health.?Records?\WAnalysis\W|Health.?Records?\WAnalyses\W|Health.?Risks?\WAppraisals?\W|Health.?Risks?\WAssessments?\W|Heart.?Rates?\WAudiometry\W|Heart.?Reactives?\WAntibodies\W|Heart.?Reactives?\WAntibody\W|Heidelberg.?Retina.?.?Angiographs?\W|Hereditary.?Renals?\WAdysplasia.?\W|High.?Right.?Atrials?\W|High.?Right.?Atrium.?\W|Histamine.?Release.?Activity\W|Histamine.?Release.?Activities\W|Histamine.?Release.?Assays?\W|Hormones?.?Receptors?\WAnalysis\W|Hormones?.?Receptors?\WAnalyses\W|(?:(?:Humans?\W|Healths?\W)Resources?\WAdministrations?\W)|Humans?\WOvarian\WCancer\WCells?\W|Humans?\WReliability\WAnalysis\W|Humans?\WReliability\WAnalyses\W|Humans?\WReliability\WAssessments?\W|Harvey\WRas\W/i){$atrisk{"HRA"}="WARNING";}
        if($abstract =~ m/Humans?\WRecombinants?\WAfgfs\W|Health.?Records?\WAnalyses\W|Health.?Risks?\WAppraisals\W|Health.?Risks?\WAssessments\W|Heart.?Reactives?\WAntibodies\W|Heidelberg.?Retina.?.?Angiographs\W|High.?Right.?Atrials\W|Histamine.?Release.?Activities\W|Histamine.?Release.?Assays\W|Hormones?.?Receptors?\WAnalyses\W|(?:(?:Humans?\W|Healths?\W)Resources?\WAdministrations\W)|Humans?\WOvarian\WCancer\WCells\W|Humans?\WReliability\WAnalyses\W|Humans?\WReliability\WAssessments\W|Harvey\WRas\W/i){$atrisk{"HRAS"}="WARNING";}
        #For the HRAS sentence
        if($abstract =~ m/Hamilton\WAnxiety\WRatings?\WScales?\W|Harvey\WRas\WOncogenes?\W|Health\WRisks?\WAssessments?\WInstruments?\W|Heart\WReactives?\WAntibodies\W/i){$atrisk{"HRAS"}="WARNING";}

        return %atrisk;
}

#Loading CCJ file
sub load_ccj{
	my $ccj = read_file('Mesh/nlmcatalog_result.txt');
	return $ccj;
}

#Loading and formatting the doaj file
sub load_doaj{
	open FICHIER,"< Mesh/doaj.txt" or die "File not available";
        my %doajs;
	while (my $ligne= <FICHIER>){
	        chomp $ligne;
	        my @sepitem=split(/\t/,$ligne);
                if(defined($sepitem[1])){$doajs{$sepitem[1]}=$sepitem[0];}
                if(defined($sepitem[2])){$doajs{$sepitem[2]}=$sepitem[0];}
	}
	close FICHIER;
	return %doajs;
}

#Loading and formatting the province file
sub load_countries{
        open FICHIER,"< Mesh/countries.csv" or die "File not available";
        my %countries;
        my $i=0;
        while (my $ligne= <FICHIER>){
                $i++;
                chomp $ligne;
                my @sepitem=split(/\;/,$ligne);
                if($i==1){next;}
                $countries{$sepitem[0]}{'code'}=$sepitem[2];
                $countries{$sepitem[0]}{'region'}=$sepitem[5];
                $countries{$sepitem[0]}{'subregion'}=$sepitem[8];
        }
        close FICHIER;
        return %countries;
}

sub load_provinces{
        open FICHIER,"< Mesh/provinces.csv" or die "File not available";
        my %provinces;
        my $i=0;
        while (my $ligne= <FICHIER>){
                $i++;
                chomp $ligne;
                my @sepitem=split(/\;/,$ligne);
                if($i==1){next;}
                $provinces{$sepitem[2]}{'code'}=$sepitem[3];
                $provinces{$sepitem[2]}{'region'}=$sepitem[4];
                $provinces{$sepitem[2]}{'subregion'}=$sepitem[5];
                $provinces{$sepitem[2]}{'name'}=$sepitem[6];
        }
        close FICHIER;
        return %provinces;
}

#Identify countries
sub identify_countries{
        my $countries=$_[0];
        my $affiliations=$_[1];
        my $provinces=$_[2];
        my %idcountries=();

        foreach my $temp(sort keys %{$countries}){
                my $temp2=$countries->{$temp}->{'code'};
                if($affiliations=~m/(\W)($temp2)(\W)/){$idcountries{$temp}=$countries->{$temp}->{'subregion'};}
                if($affiliations=~m/$temp/i){$idcountries{$temp}=$countries->{$temp}->{'subregion'};}
        }
        foreach my $temp(sort keys %{$provinces}){
                if($affiliations=~m/$temp/i){$idcountries{$provinces->{$temp}->{'name'}}=$provinces->{$temp}->{'subregion'};}
        }
        return %idcountries;
}

#All extracted PMID were checked for the existence of a free full text using the PubMed API, by 100
get '/check_countries' => sub {
    my $count=0;
    my %countries2=();
    open(LSOR, '<', $fna{'LSOR'}) or die "Could not open file '$fna{'LSOR'}' $!";
    while( my $line = <LSOR> ) {
    	chomp($line) ;
    	$count++;
        if($count>1){
	        my @sepitem=split(/\t/,$line);
	        $countries2{$sepitem[2]}=1;
        }
    }
    close LSOR;

    open(LSCO, '>', $fna{'LSCO2'}) or die "Could not open file '$fna{'LSCO2'}' $!";
    print LSCO "pmid\tcountryname\n";

    my $count=0;
    open(MAPA, '<', $fna{'MAPA'}) or die "Could not open file '$fna{'MAPA'}' $!";
    while( my $line = <MAPA> ) {
    	chomp($line) ;
    	$count++;
        if($count>1){
        	info $count;
	        my @sepitem=split(/\t/,$line);
	        if(defined($countries2{$sepitem[0]})){
                	print LSCO "$sepitem[0]\t$sepitem[6]\n";
                }
        }
    }
    close MAPA;

    close LSCO;
    return template 'index';
};

1;