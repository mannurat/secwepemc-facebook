// ==UserScript==
// @name           facebook-!TEANGA!
// @namespace      IndigenousTweets.com
// @description    Translates Facebook into !ENGLISHNAME!
// @include        http*://*.facebook.com/*
// @include        http*://facebook.com/*
// @author         Kevin Scannell
// @run-at         document-start
// @version        !LEAGAN!
// @icon           http://indigenoustweets.com/resources/gm.png
// ==/UserScript==

// Last updated:   !DATA!
// Translations:   !TRANSLATORS!

/*
 *  Copyright 2012 Kevin Scannell
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
*/


var tags = new Array();
tags.push('a');
tags.push('button'); // Like, Unlike
tags.push('h4'); // Sponsored, Ticker, ...
tags.push('label');

var classes = new Array();
classes.push('innerWrap');  // Write a comment... <textarea>
classes.push('commentActions fsm fwn fcg'); // time stamps on comments
classes.push('fsm fwn fcg');  // By:
classes.push('UIImageBlock_Content UIImageBlock_ICON_Content');  // 2 people like this
classes.push('uiImageBlockContent uiImageBlockSmallContent');  // "near"

// Replace the search string with the translated string
function r(dd, s, t) {
    if (s == t) {
        return (dd);
    } else {
        var RegExpr = new RegExp(s, "g");
        return (dd.replace(RegExpr, t));
    }
}

function translate(x) {
  d = x;
// Translations go here
  d = r(d, '(^|="|>)English \\(US\\)(?=($|"|<))', "$1"+"!NATIVENAME!");
  return d;
}

function translateOnInsert( node ) {

  for (n = 0; n < tags.length; n++) {
    var tagmatches = node.getElementsByTagName(tags[n]);
    for ( i = 0; i < tagmatches.length; i++ ) {
//      if (!tagmatches[i].hasAttribute('indigenous')) {
        if (tagmatches[i].innerHTML.match(/Wrsifjisdjfi/)) {
        GM_log('translating: '+tagmatches[i].innerHTML);
        }
        tagmatches[i].innerHTML = translate(tagmatches[i].innerHTML);
        tagmatches[i].setAttribute('indigenous', true);
//      }
    }
  }

  var divs = node.getElementsByTagName('div');
  for (i = 0; i < divs.length; i++ ) {
    for (n = 0; n < classes.length; n++) {
      if (divs[i].className == classes[n]) {
//      if (!divs[i].hasAttribute('indigenous')) {
        GM_log('translating class match ('+classes[n]+': '+divs[i].innerHTML);
        divs[i].innerHTML = translate(divs[i].innerHTML);
        divs[i].setAttribute('indigenous', true);
//      }
      }
    }
  }
}

function listen_for_change(evt)
{
  var node = evt.target;

/*
    GM_log('in change node, data='+node.data);
    GM_log('in change node, prev='+evt.prevValue);
    GM_log('in change node, new='+evt.newValue);
*/
    document.body.removeEventListener( 'DOMCharacterDataModified', listen_for_change, false );
    node.data = translate(node.data);
    document.body.addEventListener( 'DOMCharacterDataModified', listen_for_change, false );
}

function listen_for_add(evt)
{
  var node = evt.target;
  if ( node.nodeType == document.ELEMENT_NODE ) {
    document.body.removeEventListener( 'DOMNodeInserted', listen_for_add, false );
    translateOnInsert(node);
    document.body.addEventListener( 'DOMNodeInserted', listen_for_add, false );
  }
}

function initme()
{
  document.body.addEventListener( 'DOMNodeInserted', listen_for_add, false );
  document.body.addEventListener( 'DOMCharacterDataModified', listen_for_change, false );
  document.body.innerHTML = translate(document.body.innerHTML);
  //translateOnInsert(document);
}

document.addEventListener( "DOMContentLoaded", initme, false);
