#!/usr/bin/perl

use GD;
use CGI;

my $cgi = new CGI;

my $dir = "skins";

my $size = $cgi->param("size");
$size ||= 100;

my $player = $cgi->param("player");
$player ||= "steve";
$player = lc($player);

if (! -e "$dir/$player.png") {
    use LWP::Simple;
    #`echo $player >> log.txt`;
    my $response = getstore( "http://skins.minecraft.net/MinecraftSkins/$player.png", "$dir/$player.png" );
    if (!is_success($response)) {
        #print "content-type: text/html\n\nerror $response";
        #exit 0;
        $player = "steve";
    }
}

my $skin = GD::Image->newFromPng("$dir/$player.png");

#my $newImage = new GD::Image(8,8) || die;
#$newImage->copy($skin, 0, 0, 8, 8,8,8);

my $newImage = new GD::Image($size, $size) || die;
$newImage->copyResized($skin, 0, 0, 8, 8, $size, $size, 8, 8);
print "content-type: image/png\n\n";
print $newImage->png;