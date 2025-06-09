'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"assets/packages/flutter_inappwebview_web/assets/web/web_support.js": "509ae636cfdd93e49b5a6eaf0f06d79f",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Math-BoldItalic.ttf": "946a26954ab7fbd7ea78df07795a6cbc",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Script-Regular.ttf": "55d2dcd4778875a53ff09320a85a5296",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Main-Regular.ttf": "5a5766c715ee765aa1398997643f1589",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Size4-Regular.ttf": "85554307b465da7eb785fd3ce52ad282",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Typewriter-Regular.ttf": "87f56927f1ba726ce0591955c8b3b42d",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Size2-Regular.ttf": "959972785387fe35f7d47dbfb0385bc4",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Caligraphic-Regular.ttf": "7ec92adfa4fe03eb8e9bfb60813df1fa",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_AMS-Regular.ttf": "657a5353a553777e270827bd1630e467",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Main-Italic.ttf": "ac3b1882325add4f148f05db8cafd401",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Fraktur-Regular.ttf": "dede6f2c7dad4402fa205644391b3a94",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Main-BoldItalic.ttf": "e3c361ea8d1c215805439ce0941a1c8d",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_SansSerif-Regular.ttf": "b5f967ed9e4933f1c3165a12fe3436df",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Main-Bold.ttf": "9eef86c1f9efa78ab93d41a0551948f7",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_SansSerif-Bold.ttf": "ad0a28f28f736cf4c121bcb0e719b88a",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Fraktur-Bold.ttf": "46b41c4de7a936d099575185a94855c4",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Size3-Regular.ttf": "e87212c26bb86c21eb028aba2ac53ec3",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Size1-Regular.ttf": "1e6a3368d660edc3a2fbbe72edfeaa85",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Math-Italic.ttf": "a7732ecb5840a15be39e1eda377bc21d",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Caligraphic-Bold.ttf": "a9c8e437146ef63fcd6fae7cf65ca859",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_SansSerif-Italic.ttf": "d89b80e7bdd57d238eeaa80ed9a1013a",
"assets/packages/flutter_js/assets/js/fetch.js": "277e0c5ec36810cbe57371a4b7e26be0",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "95c13cec1aec17896f6b5b9821bb7350",
"assets/packages/flutter_inappwebview/assets/t_rex_runner/t-rex.html": "16911fcc170c8af1c5457940bd0bf055",
"assets/packages/flutter_inappwebview/assets/t_rex_runner/t-rex.css": "5a8d0222407e388155d7d1395a75d5b9",
"assets/packages/flex_color_picker/assets/opacity.png": "49c4f3bcb1b25364bb4c255edcaaf5b2",
"assets/AssetManifest.bin": "455e3752f74cebea578233c3cc6033b7",
"assets/fonts/MaterialIcons-Regular.otf": "c53c784fe4d733724dec25681b4d8a73",
"assets/AssetManifest.json": "db88196cd21249b4d0ffbf4ac406229b",
"assets/FontManifest.json": "e8992b70c205310bdb1568e9790e27a1",
"assets/assets/graphics/kyln24.jpeg": "04062fb98642e074c9accebbebfbd629",
"assets/assets/graphics/fsy2001.jpg": "d1e45ea831f451c97af518fbd39f7166",
"assets/assets/graphics/app_icon.ico": "7cdbb262b1ce46f765b4e2560884637a",
"assets/assets/graphics/hasbai.jpeg": "f1fdc1d1cd82fc94d94a5b1fce513932",
"assets/assets/graphics/stickers/dx_sleep.webp": "1141b2a41b31ff0e778a6fd97c9a8ca9",
"assets/assets/graphics/stickers/dx_thrill.webp": "1b84f5b373ad77b8d306ce204fc7824a",
"assets/assets/graphics/stickers/dx_caught.webp": "650ad89ff92a8dfe1f5f9ac6f09892a1",
"assets/assets/graphics/stickers/dx_craving.webp": "f5c3a3bd2c0ed86347412cd1cc5f6231",
"assets/assets/graphics/stickers/dx_roped.webp": "5ed14b777f5903aeb0adadc08f31d97b",
"assets/assets/graphics/stickers/dx_like.webp": "75103d6e4912fd331882ecc44371dcc5",
"assets/assets/graphics/stickers/dx_onlooker.webp": "4d99077e2828ddbb532c85d7296beb05",
"assets/assets/graphics/stickers/dx_kiss.webp": "c9a7f7c62291426361fb0a165c259558",
"assets/assets/graphics/stickers/dx_worn.webp": "55bb960a878879034e7a817dc34bad5c",
"assets/assets/graphics/stickers/dx_murderous.webp": "5596ada9fa856d31455909f89304bfd8",
"assets/assets/graphics/stickers/dx_twin.webp": "bbfe36247f88ac4371b48d1d33d96f38",
"assets/assets/graphics/stickers/dx_fright.webp": "c664051f9a9c5fb9738690b69faa0c86",
"assets/assets/graphics/stickers/dx_heart.webp": "492d1f96cf4c7adbd1fd16ea487d2255",
"assets/assets/graphics/stickers/dx_cate.webp": "1d832cf84fd1e17e3798baeef09b1394",
"assets/assets/graphics/stickers/dx_roll.webp": "d09332022027258df75a879b345b290a",
"assets/assets/graphics/stickers/dx_overwhelm.webp": "303ccb101ad96c3f052cbaabd37de867",
"assets/assets/graphics/stickers/dx_angry.webp": "d33661ccda379eef512855c289432cc8",
"assets/assets/graphics/stickers/dx_dying.webp": "ed29456132d40e24f2273538b841515c",
"assets/assets/graphics/stickers/dx_touch_fish.webp": "291bd0efec00908355a20921760e485f",
"assets/assets/graphics/stickers/dx_swim.webp": "993a116ab9765516ea42bb90b17febec",
"assets/assets/graphics/stickers/dx_hug.webp": "113f0ce1983342ca0b78dbe2db73753b",
"assets/assets/graphics/stickers/dx_confused.webp": "c496f7918ce9aae5d7e7ae1a2a1982ba",
"assets/assets/graphics/stickers/dx_call.webp": "20ac0f263a83efc344f0a11af53bf3e4",
"assets/assets/graphics/stickers/dx_egg.webp": "7c24082fe295cbba5ebab2a8dee9dc05",
"assets/assets/graphics/ot_logo.png": "9b7bc821e196bcc2041208463f6cedd8",
"assets/assets/graphics/Boreas618.jpg": "154adb094308aaf46375cd53698b7d89",
"assets/assets/graphics/koowz.jpg": "ec385cbeccf5c7545a2317eb206f1a20",
"assets/assets/graphics/ivanfei.jpg": "04ecf0883297db553b0b494b4ddb0f30",
"assets/assets/graphics/w568w.jpeg": "52a688cf3c32b58e04f9f3e101fba056",
"assets/assets/graphics/kavinzhao.jpeg": "c8bc3cc6c213b56d2103bf806ab62fbf",
"assets/assets/graphics/Dest1n1.jpg": "a898430901863973c1a753c94972278c",
"assets/assets/graphics/HydrogenC.jpg": "a1f2259106c1331845dbac3248fd83a5",
"assets/assets/graphics/JingYiJun.jpg": "4a7784470ae0db3d576d0ae676d3b6e1",
"assets/assets/graphics/Frankstein73.jpg": "87ee13095b84effad22219c2d3075c0e",
"assets/assets/fonts/iconfont.ttf": "10fc9d2c60416db178b25beedb6d22be",
"assets/assets/texts/care_words.dat": "52b374fed441176c3d31182005c3bbb9",
"assets/assets/texts/stop_words.dat": "654361d38d55c99cbac298d4566ac719",
"assets/assets/texts/tips.dat": "b38397c625ee54578753dadccd05e4f8",
"assets/NOTICES": "c4c6a6332cd0ff24118b2592f50be340",
"assets/AssetManifest.bin.json": "05875f0df1e30f764759729f72aff5f5",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"manifest.json": "012d91b9edf492757ddf24dd1b15d03e",
"favicon.webp": "5d8a19c576a1ba2a24af3b99f340237d",
"index.html": "83074f401aaa51b232531d3049ad73ae",
"/": "83074f401aaa51b232531d3049ad73ae",
"version.json": "e31afb07aabd4f4d840c38e41f998bc6",
"flutter_bootstrap.js": "aa38bbe398e391339c1fa6d80ddd1d14",
"main.dart.js": "12dcdca62fb60a53509ce9767053d853"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
