# The Chinese like the H5 abbreviation
addPrefixedFunction 'html' 'h5' 'Init for html5 files'
html_h5() {
  <<EOF cat -
<!DOCTYPE html>
<html lang="en">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="ie=edge">

  <!--<meta name="keywords" content="">-->
  <!--<meta name="description" content="">-->
  <!--<meta name="author" content="">-->
  <title><></title>

  <!--<link rel="icon" type="image/x-icon" href="favicon.ico">-->

  <link rel="stylesheet" type="text/css" media="screen" href="css/style.css">
  <!--<link rel="stylesheet" type="text/css" media="print" href="css/print.css">-->
  <!--<link rel="alternative stylesheet" type="text/css" media="screen" href="css/accessibility.css"> -->
  <script type="text/javascript"></script>
  <!--<script type="text/javascript" src="src/app.js"></script>-->
</head>

<body>
  <>
</body>
</html>
EOF
}

addPrefixedFunction 'html' 'h4' 'Init for html4 files'
html_h4() {
  <<EOF cat -
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html lang="en">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="ie=edge">

  <!--<meta name="keywords" content="">-->
  <!--<meta name="description" content="">-->
  <!--<meta name="author" content="">-->
  <title><></title>

  <!--<link rel="icon" type="image/x-icon" href="favicon.ico">-->

  <link rel="stylesheet" type="text/css" media="screen" href="css/style.css">
  <!--<link rel="stylesheet" type="text/css" media="print" href="css/print.css">-->
  <!--<link rel="alternative stylesheet" type="text/css" media="screen" href="css/accessibility.css"> -->
  <script type="text/javascript"></script>
  <!--<script type="text/javascript" src="src/app.js"></script>-->
</head>
<body>
  <>
</body>
</html>
EOF
}

addPrefixedFunction 'html' 'script' 'script tag with text/javascript'
html_script() {
  # https://stackoverflow.com/questions/20771400#answer-20771411
  printf %s '<script type="text/javascript"><></script>'
}

addPrefixedFunction 'html' 'table' 'Table skeleton'
html_table() {
  printf %s '<table><><tr><td><></td><></tr><></table>'
}

addPrefixedFunction 'html' 'lorem_la' 'Lorem ipsum in latin'
html_lorem_la() {
<<EOF cat -
<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
In dictum non consectetur a erat nam at lectus urna.
In est ante in nibh.
Mus mauris vitae ultricies leo integer malesuada.
Aliquam etiam erat velit scelerisque in dictum non consectetur a.
Ullamcorper dignissim cras tincidunt lobortis feugiat vivamus at augue.
At ultrices mi tempus imperdiet.
Tincidunt lobortis feugiat vivamus at augue eget arcu dictum.
Sodales ut eu sem integer vitae justo eget magna.
Pellentesque elit eget gravida cum sociis natoque.
Consectetur adipiscing elit pellentesque habitant morbi tristique.
Viverra justo nec ultrices dui sapien eget mi.
Enim sit amet venenatis urna cursus eget nunc.
Commodo sed egestas egestas fringilla phasellus faucibus scelerisque.
Mauris sit amet massa vitae tortor.
Pulvinar neque laoreet suspendisse interdum consectetur libero.
Mattis aliquam faucibus purus in massa.</p>

<p>At risus viverra adipiscing at in tellus.
Molestie a iaculis at erat pellentesque.
Non arcu risus quis varius quam.
Phasellus vestibulum lorem sed risus ultricies.
Netus et malesuada fames ac turpis egestas maecenas pharetra convallis.
Morbi leo urna molestie at elementum eu.
Odio euismod lacinia at quis risus sed.
Semper quis lectus nulla at volutpat diam ut venenatis.
Rutrum quisque non tellus orci ac auctor augue.
Malesuada fames ac turpis egestas.
Adipiscing enim eu turpis egestas pretium aenean pharetra.
Eget arcu dictum varius duis at.
Neque ornare aenean euismod elementum nisi quis eleifend quam.
Sit amet massa vitae tortor condimentum lacinia quis.
Cursus mattis molestie a iaculis at erat pellentesque.
Egestas egestas fringilla phasellus faucibus.
Gravida cum sociis natoque penatibus.
Sit amet consectetur adipiscing elit pellentesque habitant morbi tristique.</p>

<p>Nunc pulvinar sapien et ligula ullamcorper malesuada proin libero.
Egestas fringilla phasellus faucibus scelerisque eleifend donec.
Diam maecenas sed enim ut sem viverra aliquet eget.
Non sodales neque sodales ut etiam.
Vel turpis nunc eget lorem.
Viverra nam libero justo laoreet sit amet cursus sit amet.
Sed odio morbi quis commodo odio.
Id venenatis a condimentum vitae sapien pellentesque habitant morbi tristique.
Laoreet sit amet cursus sit amet dictum sit amet justo.
Et leo duis ut diam quam nulla.
Scelerisque viverra mauris in aliquam sem.</p>

<p>Dui faucibus in ornare quam viverra.
Facilisis volutpat est velit egestas dui id ornare.
Sapien nec sagittis aliquam malesuada bibendum arcu vitae elementum.
Lobortis feugiat vivamus at augue eget arcu dictum varius.
Risus feugiat in ante metus dictum at tempor commodo.
Montes nascetur ridiculus mus mauris vitae ultricies leo.
Sem fringilla ut morbi tincidunt augue interdum velit euismod.
Orci porta non pulvinar neque.
Tincidunt tortor aliquam nulla facilisi cras.
Habitant morbi tristique senectus et netus.
Nascetur ridiculus mus mauris vitae ultricies.
Venenatis tellus in metus vulputate eu scelerisque felis.
Amet mattis vulputate enim nulla aliquet porttitor lacus.
Sed turpis tincidunt id aliquet risus feugiat in.
Vel fringilla est ullamcorper eget nulla facilisi etiam dignissim diam.
Faucibus ornare suspendisse sed nisi lacus sed.
Malesuada pellentesque elit eget gravida cum sociis natoque.
Turpis massa tincidunt dui ut ornare lectus sit.</p>

<p>Aliquet risus feugiat in ante metus dictum.
Turpis egestas sed tempus urna et.
Viverra ipsum nunc aliquet bibendum enim facilisis gravida neque convallis.
Ultrices gravida dictum fusce ut placerat orci.
Cras sed felis eget velit aliquet sagittis id consectetur purus.
Volutpat consequat mauris nunc congue nisi vitae suscipit.
Donec et odio pellentesque diam volutpat commodo sed egestas egestas.
Malesuada nunc vel risus commodo viverra.
Id diam vel quam elementum pulvinar etiam non.
Maecenas ultricies mi eget mauris pharetra et ultrices neque.
Volutpat commodo sed egestas egestas fringilla phasellus faucibus scelerisque.
Nunc id cursus metus aliquam eleifend.
Nulla porttitor massa id neque aliquam vestibulum morbi.
Id nibh tortor id aliquet lectus.
Sollicitudin aliquam ultrices sagittis orci.</p>
EOF
}



addPrefixedFunction 'html' 'lorem_jp' 'Lorem ipsum equivalent in Japanese'
html_lorem_jp() {
<<EOF cat -
  <p>何は時間けっしてこんな話事ってののためがありなけれます。
  けっして十一月と観念家はもしその＃「たんなりを思っばいたでは観念組み立てませたて、はっきりには待っないたますです。
  大学がありだつもりもおっつけ前をとうていたますまし。
  よく張さんが説明所々突然想像に強いるだ理由その働あなたか構成にとしてご拡張たませでしでで、その先刻も私か市街自力を尽さが、嘉納さんののよりご免の私をどうぞご矛盾とできるが私人に小交渉を困るようにどうもお学習にできるなけれないて、単にしかるに乱暴にありまして行くありのに及ぼすんざる。</p>

  <p>すなわち例えばご先と弱ら事は始終面倒と使おですて、この半途にもなるですてに対して理由に取り消せのでみるですた。
  そんな中気味のためどんな手段は私上が困るなくかと大森さんに断っましです、秋刀魚の平生でしにおいてお衰弱たでませて、金の時へ道徳に時間かもの置に今朝考えからしまえと、当然のほかからありがそのためにはなはだ恐れ入りましだと嫌うた事ましと、ないませますばまだお各人なるですのですなん。</p>

  <p>または社か自由か圧迫でできるないば、直接いっぱいご免が間違っがいるですところにごお話の今日のありたた。
  昨日がもさぞ行っていうないならですないと、ついにすでにあるて任命はもう少しなしなのう。
  また同発表がありてはみるますものだと、シャツからは、はなはだあれかなさると申しられでざる弱られるですたと破るで、傍点はしのでいたな。</p>

  <p>どうももっともはよほどモーニングといういるんて、私をは場合末までどこのご誘惑もたまらなく飲んいですだ。
  私はつい運動ののにご汚辱はあっのでいるるあっなけれですて、一五の学校をあまりしよたくという招待んて、ただその規律の社が逃れれと、皆かが私の字で矛盾を当てて下さらな事ですないと発表読んてらくしいるべきです。
  ろがただ岡田さんを実は少し云いた訳ただた。
  嘉納君はなぜ国家になるから聞かですものないうです。</p>

  <p>私ははたして一部分がしですようにしてみろたのましょからところがとても倫敦ろましますう。
  また全く一年は通りに窮めので、一番をよく破るですまいとあって、ないたなてだからお＃「で行きたなら。
  骨の場合に、その主義をすべてでするぐらい、ほかごろがたった九月二何十人にしだけの次を、私か抱いなお話がいう先刻もよく這入っられものうて、どうしても始終例に憂と、その方が進まのが不幸ですない叱らたた。
  もしくはもっと今一二二本にするかもはしないという丁寧た変化が云うて、現象にある後その所を得ているた方た。</p>

  <p>そのうちに画で手段いです三一年事実がして、それらか考えですて得るでとかいう気であいにく行くまし訳だて、とうとう引張りのを高等たば、ひとまず手数がいうば来るて来でで。</p>

  <p>他人にあっと勧めて私かなかっのに向いように立っでも掴みただって、また他愛は高い方で思わが、そこが人格をやるって三篇を一本は二行もともかく釣らがいるじゃまいものだ。
  十一月ないたかなっ廃墟を起るて、ある国家は自由なし立派淋しいと堪です事ですはしますな、好い様子の頃よりしなかっ教授なけれ至ると思うてしまうまし事ましな。</p>

  <p>しかし我々も自由ないてぶつかるたい事なくはわるけれ、簡単だながら閉じ込めた事んとして私の人の年にその世間を卒業いうがならますです。</p>

  <p>国家にも失礼たもしするけれどもえれです昔を文壇が過ぎと、著書を知れたり、しかし兄をあるとか反し他人に云っ傾向、必要ですから、かつて堪とありがたく先方をみたといるから、素因が承て哲学まで生徒までを申す鷹狩はしです。
  つまり自然ではその先生の愉快借着に九月になっん中に込み入っからとにかく蹂躙なっばいる次第を進んのまし。
  またどこはそのうちに用いよ云わのます、発会の一条に混同忘れです仕方がはなっですうて好いはたべないです。
  とやかくこれもこの自由なかっ鶴嘴に述べるかもた、批評の主義にまるでするましにするのでしまうなくのまし。
  しきりにできるだけ一一五人からするませて、責任がも教場がは私を教場を与えましてするんのを述べるんまし。</p>

  <p>しかし今別段国でありていたんけれども、説明を始めて蹂躙のようまし。
  こうお束縛をいうようでしょ啓発は見くれないば、こののがご新科学よりしでしょ。
  この作物はどこ末に始めが元来だけさてみのか罹っないですて、その所私にたいてあなたの地位が怒って得るて、自失を至るられのは、文学の釣とともについに重大たですて私は起っからしまうのでて、また時が賑わすて、ちょっと私児のろかしようだ恐ろしい品評は、よし何にその人をできるばおきからは普通に云うれのんはませたとは眺めるんあり。
  私先生でもまたここの場所で道ですあり点ませは焼いなけれないか。</p>

  <p>どちらを異存団に答えます招待の以上でその観念がちのに会っなけれ。
  今応じくれお国家で二度目黒文章を自分にして、興味富を私立な知れた中、変則状態のかかわらたて、当然個人の妨害はなかっ、右とも事に下すて裏面に行か他人にいいのが喰わた、問題ないに十年は私を感ずる大きくた否家が人わしし、それかも掘りて考えと知れないそうます。
  ただどういう片仮名の方々とか示威と主義をという、できるの学校をいと二人の理由を秋刀魚の握っでとなるで。</p>
EOF
}

# The 千字文 from Wikipedia which sources from:
#     https://web.archive.org/web/20190403231106/http://www.oocities.org/npsturman/tce.html
addPrefixedFunction 'html' 'lorem_wy' 'Lorem ipsum equivalent in Classical Chinese'
html_lorem_wy() {
<<EOF cat -
<p>天地玄黃，宇宙洪荒。
日月盈昃，辰宿列張。
寒來暑往，秋收冬藏。
閏餘成歲，律呂調陽。
雲騰致雨，露結為霜。
金生麗水，玉出崑岡。
劍號巨闕，珠稱夜光。
果珍李柰，菜重芥薑。
海鹹河淡，鱗潛羽翔。</p>

<p>龍師火帝，鳥官人皇。
始制文字，乃服衣裳。
推位讓國，有虞陶唐。
弔民伐罪，周發殷湯。
坐朝問道，垂拱平章。
愛育黎首，臣伏戎羌。
遐邇一體，率賓歸王。
鳴鳳在竹，白駒食場。
化被草木，賴及萬方。</p>

<p>蓋此身髮，四大五常。
恭惟鞠養，豈敢毀傷。
女慕貞絜，男效才良。
知過必改，得能莫忘。
罔談彼短，靡恃己長。
信使可覆，器欲難量。
墨悲絲染，詩讚羔羊。
景行維賢，克念作聖。
德建名立，形端表正。
空谷傳聲，虛堂習聽。
禍因惡積，福緣善慶。
尺璧非寶，寸陰是競。
資父事君，曰嚴與敬。
孝當竭力，忠則盡命。
臨深履薄，夙興溫凊。
似蘭斯馨，如松之盛。
川流不息，淵澄取映。
容止若思，言辭安定。
篤初誠美，慎終宜令。
榮業所基，藉甚無竟。
學優登仕，攝職從政。
存以甘棠，去而益詠。
樂殊貴賤，禮別尊卑。
上和下睦，夫唱婦隨。
外受傅訓，入奉母儀。
諸姑伯叔，猶子比兒。
孔懷兄弟，同氣連枝。
交友投分，切磨箴規。
仁慈隱惻，造次弗離。
節義廉退，顛沛匪虧。</p>

<p>都邑華夏，東西二京。
背邙面洛，浮渭據涇。
宮殿盤郁，樓觀飛驚。
圖寫禽獸，畫彩仙靈。
丙舍傍啟，甲帳對楹。
肆筵設席，鼓瑟吹笙。
升階納陛，弁轉疑星。
右通廣內，左達承明。
既集墳典，亦聚群英。
杜稿鍾隸，漆書壁經。
府羅將相，路俠槐卿。
戶封八縣，家給千兵。
高冠陪輦，驅轂振纓。
世祿侈富，車駕肥輕。
策功茂實，勒碑刻銘。
磻溪伊尹，佐時阿衡。
奄宅曲阜，微旦孰營。
桓公匡合，濟弱扶傾。
綺回漢惠，說感武丁。
俊乂密勿，多士寔寧。
晉楚更霸，趙魏困橫。
假途滅虢，踐土會盟。
何遵約法，韓弊煩刑。
起翦頗牧，用軍最精。
宣威沙漠，馳譽丹青。
九州禹跡，百郡秦并。
岳宗泰岱，禪主云亭。
雁門紫塞，雞田赤城。
昆池碣石，鉅野洞庭。
曠遠綿邈，岩岫杳冥。
性靜情逸，心動神疲。
守真志滿，逐物意移。
堅持雅操，好爵自縻。</p>

<p>治本於農，務茲稼穡。
俶載南畝，我藝黍稷。
稅熟貢新，勸賞黜陟。
孟軻敦素，史魚秉直。
庶幾中庸，勞謙謹敕。
聆音察理，鑒貌辨色。
貽厥嘉猷，勉其祗植。
省躬譏誡，寵增抗極。
殆辱近恥，林皋幸即。
兩疏見機，解組誰逼。
索居閒處，沉默寂寥。
求古尋論，散慮逍遙。
欣奏累遣，慼謝歡招。
渠荷的歷，園莽抽條。
枇杷晚翠，梧桐蚤凋。
陳根委翳，落葉飄搖。
游鵾獨運，凌摩絳霄。</p>

<p>耽讀玩市，寓目囊箱。
易輶攸畏，屬耳垣牆。
具膳餐飯，適口充腸。
飽飫烹宰，飢厭糟糠。
親戚故舊，老少異糧。
妾御績紡，侍巾帷房。
紈扇圓潔，銀燭煒煌。
晝眠夕寐，藍筍象床。
弦歌酒宴，接杯舉觴。
矯手頓足，悅豫且康。
嫡後嗣續，祭祀烝嘗。
稽顙再拜，悚懼恐惶。
箋牒簡要，顧答審詳。
骸垢想浴，執熱願涼。
驢騾犢特，駭躍超驤。
誅斬賊盜，捕獲叛亡。</p>

<p>布射僚丸，嵇琴阮嘯。
恬筆倫紙，鈞巧任釣。
釋紛利俗，竝皆佳妙。
毛施淑姿，工顰妍笑。
年矢每催，曦暉朗曜。
璿璣懸斡，晦魄環照。
指薪修祜，永綏吉劭。
矩步引領，俯仰廊廟。
束帶矜庄，徘徊瞻眺。
孤陋寡聞，愚蒙等誚。
謂語助者，焉哉乎也。</p>
EOF
}
