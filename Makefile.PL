use ExtUtils::MakeMaker;

my $mm = new MM
 (
  {
   AUTHOR => "Daniel Ruoso <daniel\@ruoso.com>",
   ABSTRACT => "Perl Oak Component Tree",
   NAME => "Oak::IO::DBI",
   VERSION => "1.8",
   PREREQ_PM => 
   {
    'DBI' => '1.35',
    'Error' => '0.15',
    'Oak::Component' => '0'
   }
  }
 );

$mm->flush;
