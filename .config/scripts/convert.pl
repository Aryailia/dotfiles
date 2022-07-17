#!/usr/bin/perl

use v5.28;                     # in perluniintro, latest bug fix for unicode
#use feature 'unicode_strings'; # enable perl functions to use Unicode
#use Encode 'decode_ut8';       # so we do not need -CA flag in perl
#use utf8;                      # source code in utf8
use strict 'subs';             # only allows declared functions
use warnings;
use JSON;
use POSIX;

#binmode STDIN, ':encoding(utf8)';
#binmode STDOUT, ':encoding(utf8)';
#binmode STDERR, ':encoding(utf8)';

sub help {
  print STDERR
    "'$_[0]' is not a supported format\n",
    "e.g.\n",
    "    currency:    250 yen to dollar\n",
    "    currency:    250 japan to usa\n",
    "    currency:    250 yen\n",
    "    currency:    offline 250 yen\n",
    "    temperature: 175C \n",
    "\n",
    "Supports:\n",
  ;

  open(FILE, "<$0") or die "Trouble reading help from source file '$0'";
  foreach (<FILE>) {
    $_ =~ / +# help: (.+)/ and say("  $1");
  }
  close(FILE);
  exit 1;
}

# Declare so they are in the accessible variable namespace
my ($local_rates, %abrv);

# run: perl % local 250 jp to us
# run: perl % tz
sub main {
  my $arg = join(" ", @ARGV);
  # help: Celsius (C), Fahrenheit (F), Kelvin (K)
  if    ($arg =~ /^(\d+)\s*C/i) { printf "%f F\n", $1 * 9 / 5 + 32; }
  elsif ($arg =~ /^(\d+)\s*F/i) { printf "%f C\n", ($1 - 32) * 5 / 9; }
  elsif ($arg =~ /^(\d+)\s*K/i) { printf "%f C\n", $1 + 273.15; }

  # help: Ounces, Fluid Ounces
  elsif ($arg =~ /^(\d+)\s*ounce/i)       { printf "%f g\n", $1 * 28.34; }
  elsif ($arg =~ /^(\d+)\s*fluid ounce/i) { printf "%f ml\n", $1 * 28.41; }

  # help: update currencies (-u)
  elsif ($arg eq "-u") {
    my $exchange_rates = scrap_exchange_rates();
    print(JSON->new->utf8->pretty->encode($exchange_rates));

  # help: offline/local currency (local 250 jp to us)
  } elsif ($arg =~ /^(?:offline|local)\s+(\d+)\s*(\w+)\s+to\s+(\w+)/i) {
    convert_currency($local_rates, $1, $2, $3);

  } elsif ($arg =~ /^(\d+)\s*(\w+)\s+to\s+(\w+)/i) {
    my $exchange_rates = scrap_exchange_rates();
    convert_currency($exchange_rates, $1, $2, $3);

  # https://github.com/dr5hn/countries-states-cities-database
  # help: timezone (e.g. `$0 tz Malaysia`)
  } elsif ($arg =~ /^tz|timezone/i) {
    $ENV{'DOTENVIRONMENT'} =~ /(\/.+)/ or die '$DOTENVIRONMENT undefined';
    #my $file = "$1/countries+cities.json";
    my $file = "$1/countries+states.json";
    my $choice = qx(jq -r 'map(.name) | join("\n")' $file | fzf) or exit $?;
    chomp $choice;
    say qx(jq 'map(select(.name == "$choice"))[0].timezones' $file);
    #open(FILE, "<$file") or die "Could not find '$file'";
    #my $database = JSON->new->utf8->decode(join '', <FILE>);
    #close FILE;

  # help: timezone (e.g. `$0 tz Malaysia`)
  } elsif ($arg =~ /^(?:tz|timezone) (.*)/i ) {


  # https://hacks.mozilla.org/2017/12/using-headless-mode-in-firefox/
  # help: HTML to png
  } elsif ($arg =~ /^https?:|.html$/i) {
    say "chromium --headless --disable-gpu --window-size=700,300 --screenshot=<./save-path> <html-path>";
    say "firefox --headless ---screenshot <html-path>";
  } else  { help($arg); }
}

# Scrap xe.com (this is what duckduckgo uses)
sub scrap_exchange_rates {
  # They provide a JSON data structure with all the exchange rates with
  # every specific currency conversion
  my $scraping = qx(
    curl "https://www.xe.com/currencyconverter/convert/?Amount=1&From=CNY&To=USD" \\
      | pup 'script[id="__NEXT_DATA__"] text{}'
  );
  my $json = JSON->new->utf8->decode($scraping);
  my $exchange_rates = $json->{"props"}->{"pageProps"}->{"initialRatesData"};
  return $exchange_rates;
}

sub convert_currency {
  my ($exchange_rates, $amount, $source, $target) = @_;
  $source = lc($source);
  $target = lc($target);
  exists $abrv{$source} ? $source = $abrv{$source} : die "Invalid abbreviation '$source'";
  exists $abrv{$target} ? $target = $abrv{$target} : die "Invalid abbreviation '$target'";

  my $timestamp = $exchange_rates->{"timestamp"};
  my %rates = %{$exchange_rates->{"rates"}};

  say "Valid at: ", POSIX::strftime("%Y-%m-%d", localtime($timestamp / 1000));
  my $exchanged = $amount / $rates{$source} * $rates{$target};
  printf "$amount $source \n-> %.2f $target\n", $exchanged;
}


# What $exchange_rates looks like
# We will update this manually by running `$0 -u` and copy pasting
$local_rates = JSON->new->utf8->decode('{
  "timestamp": 1643743680000,
  "rates": {
    "AED": 3.6725,
    "AFN": 100.4673212042,
    "ALL": 107.7970161579,
    "AMD": 481.9642451953,
    "ANG": 1.7896253768,
    "AOA": 532.0164047417,
    "ARS": 105.1205998395,
    "ATS": 12.2306591373,
    "AUD": 1.4058902461,
    "AWG": 1.79,
    "AZM": 8494.8918530696,
    "AZN": 1.6989783706,
    "BAM": 1.7384134111,
    "BBD": 2,
    "BDT": 85.7605829486,
    "BEF": 35.8555821117,
    "BGN": 1.7384134111,
    "BHD": 0.376,
    "BIF": 2008.6800686634,
    "BMD": 1,
    "BND": 1.349158938,
    "BOB": 6.8789897675,
    "BRL": 5.2721158819,
    "BSD": 1,
    "BTN": 74.7470682012,
    "BWP": 11.6715049899,
    "BYN": 2.584577692,
    "BYR": 25845.7769201481,
    "BZD": 2.0144290107,
    "CAD": 1.2695703171,
    "CDF": 1995.4994808656,
    "CHF": 0.9218338141,
    "CLF": 0.0290929364,
    "CLP": 802.7173566938,
    "CNH": 6.3722576461,
    "CNY": 6.3630254593,
    "COP": 3920.9207103116,
    "CRC": 640.7512805927,
    "CUC": 1,
    "CUP": 24.0472194317,
    "CVE": 98.0120188562,
    "CYP": 0.5202129892,
    "CZK": 21.5829718413,
    "DEM": 1.7384134111,
    "DJF": 177.7695394895,
    "DKK": 6.6127042204,
    "DOP": 57.6920159171,
    "DZD": 140.3246076932,
    "EEK": 13.9073072886,
    "EGP": 15.7083427269,
    "ERN": 15,
    "ESP": 147.889977051,
    "ETB": 49.8045109373,
    "EUR": 0.8888366632,
    "FIM": 5.2847828138,
    "FJD": 2.1587058905,
    "FKP": 0.7399870506,
    "FRF": 5.8303863111,
    "GBP": 0.7399870506,
    "GEL": 3.0347924994,
    "GGP": 0.7399870506,
    "GHC": 62788.4103625629,
    "GHS": 6.2788410363,
    "GIP": 0.7399870506,
    "GMD": 52.9929696474,
    "GNF": 9013.2986769819,
    "GRD": 302.8710930013,
    "GTQ": 7.6818951832,
    "GYD": 208.798454999,
    "HKD": 7.7941584728,
    "HNL": 24.573755552,
    "HRK": 6.694052647,
    "HTG": 102.6691801931,
    "HUF": 316.2126308739,
    "IDR": 14364.8269275075,
    "IEP": 0.7000157579,
    "ILS": 3.1690215525,
    "IMP": 0.7399870506,
    "INR": 74.7470682012,
    "IQD": 1459.3976608978,
    "IRR": 42137.4348509361,
    "ISK": 127.6694310555,
    "ITL": 1721.0277659446,
    "JEP": 0.7399870506,
    "JMD": 156.0439059104,
    "JOD": 0.709,
    "JPY": 114.7124906966,
    "KES": 113.5948104357,
    "KGS": 84.7971076067,
    "KHR": 4067.472921431,
    "KMF": 437.278973335,
    "KPW": 900.0101804573,
    "KRW": 1204.4064025257,
    "KWD": 0.3027961303,
    "KYD": 0.8200027472,
    "KZT": 434.1486457336,
    "LAK": 11318.5763483166,
    "LBP": 1507.5,
    "LKR": 202.5273092606,
    "LRD": 152.4714994954,
    "LSL": 15.2816022672,
    "LTL": 3.0689752309,
    "LUF": 35.8555821117,
    "LVL": 0.6246744069,
    "LYD": 4.6194211267,
    "MAD": 9.3905318314,
    "MDL": 17.9855862697,
    "MGA": 3999.1058466584,
    "MGF": 19995.529233292,
    "MKD": 54.8424892807,
    "MMK": 1777.1308327625,
    "MNT": 2864.6009633447,
    "MOP": 8.027983227,
    "MRO": 364.0482391102,
    "MRU": 36.404823911,
    "MTL": 0.3815775795,
    "MUR": 43.6653268472,
    "MVR": 15.4099929318,
    "MWK": 817.3090326478,
    "MXN": 20.6103300834,
    "MXV": 3.0174297813,
    "MYR": 4.1856017633,
    "MZM": 63843.1670450117,
    "MZN": 63.843167045,
    "NAD": 15.2816022672,
    "NGN": 414.7593768879,
    "NIO": 35.4010179456,
    "NLG": 1.9587382432,
    "NOK": 8.8535031197,
    "NPR": 119.6513694231,
    "NZD": 1.5078459105,
    "OMR": 0.3845,
    "PAB": 1,
    "PEN": 3.8805724682,
    "PGK": 3.5087578516,
    "PHP": 51.0822384463,
    "PKR": 176.3105822489,
    "PLN": 4.061133269,
    "PTE": 178.195751921,
    "PYG": 7062.2718555662,
    "QAR": 3.64,
    "ROL": 43963.5309576874,
    "RON": 4.3963530958,
    "RSD": 104.527891136,
    "RUB": 76.8597455687,
    "RWF": 1037.0473133679,
    "SAR": 3.75,
    "SBD": 8.1311857979,
    "SCR": 14.5043410639,
    "SDD": 44097.5969357958,
    "SDG": 440.975969358,
    "SEK": 9.2783759216,
    "SGD": 1.349158938,
    "SHP": 0.7399870506,
    "SIT": 213.0008179804,
    "SKK": 26.777093317,
    "SLL": 11440.7809959645,
    "SOS": 574.1533296395,
    "SPL": 0.166666666,
    "SRD": 20.9062070304,
    "SRG": 20906.2070304049,
    "STD": 21960.4595743551,
    "STN": 21.9604595744,
    "SVC": 8.75,
    "SYP": 2512.5363231101,
    "SZL": 15.2816022672,
    "THB": 33.1966204031,
    "TJS": 11.2841709051,
    "TMM": 18218.1756142763,
    "TMT": 3.6436351229,
    "TND": 2.8896215327,
    "TOP": 2.2904270096,
    "TRL": 13382039.22054201,
    "TRY": 13.3820392205,
    "TTD": 6.7750860879,
    "TVD": 1.4058902461,
    "TWD": 27.8051240244,
    "TZS": 2311.9236372676,
    "UAH": 28.4378149485,
    "UGX": 3495.9674964422,
    "USD": 1,
    "UYU": 43.9133274181,
    "UZS": 10831.5172335807,
    "VAL": 1721.0277659446,
    "VEB": 453182168.53753215,
    "VED": 4.531844849,
    "VEF": 453184.4848979032,
    "VES": 4.531844849,
    "VND": 22673.2569230055,
    "VUV": 115.0269395975,
    "WST": 2.6579605847,
    "XAF": 583.0386311133,
    "XAG": 0.0443460915,
    "XAU": 0.000555278,
    "XBT": 2.59884e-05,
    "XCD": 2.7024560303,
    "XDR": 0.7157436924,
    "XOF": 583.0386311133,
    "XPD": 0.0004268001,
    "XPF": 106.0664275947,
    "XPT": 0.0009749304,
    "YER": 250.2898408972,
    "ZAR": 15.2816022672,
    "ZMK": 18100.1451427441,
    "ZMW": 18.1001451427,
    "ZWD": 361.9
  }
}');

# Cause vim syntax highlighting might not detect this far, end the quote
# '

%abrv = (
  # China, PRC
  'yuan' => 'CNY',
  'china' => 'CNY',
  'cn' => 'CNY',
  'zh' => 'CNY',

  # Japan
  'yen' => 'JPY',
  'japan' => 'JPY',
  'jp' => 'JPY',

  # Korea
  'won' => 'KRW',
  'korea' => 'KRW',
  'kr' => 'KRW',

  # Mauritius
  'mauritius' => 'MUR',
  'rs' => 'MUR',
  'mu' => 'MUR',


  # Malaysia
  'malaysia' => 'MYR',
  'rm' => 'MYR',
  'my' => 'MYR',

  # Taiwan, ROC
  'taiwan' => 'TWD',
  'roc' => 'TWD',
  'tw' => 'TWD',

  # UK
  'pound' => 'GBP',
  'uk' => 'GBP',

  # USA
  'dollar' => 'USD',
  'usa' => 'USD',
  'us' => 'USD',
);

foreach my $key (keys %{$local_rates->{"rates"}}) {
  $abrv{lc($key)} = uc($key);
}


main();
