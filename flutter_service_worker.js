'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter.js": "383e55f7f3cce5be08fcf1f3881f585c",
"canvaskit/skwasm.worker.js": "bfb704a6c714a75da9ef320991e88b03",
"canvaskit/skwasm.js": "5d4f9263ec93efeb022bb14a3881d240",
"canvaskit/canvaskit.js.symbols": "74a84c23f5ada42fe063514c587968c6",
"canvaskit/skwasm.js.symbols": "c3c05bd50bdf59da8626bbe446ce65a3",
"canvaskit/chromium/canvaskit.js.symbols": "ee7e331f7f5bbf5ec937737542112372",
"canvaskit/chromium/canvaskit.js": "901bb9e28fac643b7da75ecfd3339f3f",
"canvaskit/chromium/canvaskit.wasm": "399e2344480862e2dfa26f12fa5891d7",
"canvaskit/canvaskit.js": "738255d00768497e86aa4ca510cce1e1",
"canvaskit/canvaskit.wasm": "9251bb81ae8464c4df3b072f84aa969b",
"canvaskit/skwasm.wasm": "4051bfc27ba29bf420d17aa0c3a98bce",
"flutter_bootstrap.js": "3f758761755a0b279594bf255d2aa57e",
"version.json": "623239ecd42aa3b34d895d0db0e0a46d",
"favicon.webp": "5d8a19c576a1ba2a24af3b99f340237d",
"main.dart.js": "3244d9856eccc5c0c3aa7088d2876163",
"assets/NOTICES": "b7d3d2875212568b62a51e0d37ab2c7b",
"assets/AssetManifest.bin": "8ae4ea573da4341dfd18c7a1b750fab8",
"assets/assets/graphics/kyln24.jpeg": "04062fb98642e074c9accebbebfbd629",
"assets/assets/graphics/kavinzhao.jpeg": "c8bc3cc6c213b56d2103bf806ab62fbf",
"assets/assets/graphics/ot_logo.png": "9b7bc821e196bcc2041208463f6cedd8",
"assets/assets/graphics/Frankstein73.jpg": "87ee13095b84effad22219c2d3075c0e",
"assets/assets/graphics/JingYiJun.jpg": "4a7784470ae0db3d576d0ae676d3b6e1",
"assets/assets/graphics/HydrogenC.jpg": "a1f2259106c1331845dbac3248fd83a5",
"assets/assets/graphics/Dest1n1.jpg": "a898430901863973c1a753c94972278c",
"assets/assets/graphics/stickers/dx_twin.jpg": "3bcb38aed2617de05d9125c79a3efffd",
"assets/assets/graphics/stickers/dx_heart.jpg": "5298b66be0a88a26b9329986f013d1ad",
"assets/assets/graphics/stickers/dx_hug.jpg": "195d9642dc52bb3fcfee7853f7f31222",
"assets/assets/graphics/stickers/dx_dying.jpg": "aa24928f9b1fc918cf3e2b19e39ef8ee",
"assets/assets/graphics/stickers/dx_cate.jpg": "30f77173baa996d3298110470904f50f",
"assets/assets/graphics/stickers/dx_sleep.jpg": "c7a579f4f1a6c329471c026fd75de62b",
"assets/assets/graphics/stickers/dx_touchFish.jpg": "760ea6fe5afec1e3d6e6ae619a23a65e",
"assets/assets/graphics/stickers/dx_roll.jpg": "6c11f433990d624ef7dd4210937329f6",
"assets/assets/graphics/stickers/dx_overwhelm.jpg": "40c4c8523a1877947471ef72345cebcd",
"assets/assets/graphics/stickers/dx_egg.jpg": "030af1a57d6282d72366d89bd4cee053",
"assets/assets/graphics/stickers/dx_swim.jpg": "1411ca4d74e35fc64ab8f961e031093b",
"assets/assets/graphics/stickers/dx_thrill.jpg": "e5be9bf7cfe53ee6b2fac0802c338481",
"assets/assets/graphics/stickers/dx_fright.jpg": "6d4853dbe8db9d79d6f38545e9c3bb73",
"assets/assets/graphics/stickers/dx_roped.jpg": "f26bc98723786dd5217848f16efe95f7",
"assets/assets/graphics/stickers/dx_angry.jpg": "b4965fedec0244e0c79baf39f08cca9c",
"assets/assets/graphics/stickers/dx_call.jpg": "82c95951a1e6aece5f36386fad84af4b",
"assets/assets/graphics/fsy2001.jpg": "d1e45ea831f451c97af518fbd39f7166",
"assets/assets/graphics/koowz.jpg": "ec385cbeccf5c7545a2317eb206f1a20",
"assets/assets/graphics/app_icon.ico": "7cdbb262b1ce46f765b4e2560884637a",
"assets/assets/graphics/w568w.jpeg": "52a688cf3c32b58e04f9f3e101fba056",
"assets/assets/graphics/Boreas618.jpg": "154adb094308aaf46375cd53698b7d89",
"assets/assets/graphics/hasbai.jpeg": "f1fdc1d1cd82fc94d94a5b1fce513932",
"assets/assets/graphics/ivanfei.jpg": "04ecf0883297db553b0b494b4ddb0f30",
"assets/assets/fonts/iconfont.ttf": "10fc9d2c60416db178b25beedb6d22be",
"assets/assets/texts/stop_words.dat": "654361d38d55c99cbac298d4566ac719",
"assets/assets/texts/tips.dat": "fa882da0f7fc6a6d6dab3772fc814a88",
"assets/assets/texts/care_words.dat": "52b374fed441176c3d31182005c3bbb9",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Size2-Regular.ttf": "959972785387fe35f7d47dbfb0385bc4",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Fraktur-Bold.ttf": "46b41c4de7a936d099575185a94855c4",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Size4-Regular.ttf": "85554307b465da7eb785fd3ce52ad282",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Caligraphic-Regular.ttf": "7ec92adfa4fe03eb8e9bfb60813df1fa",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_SansSerif-Bold.ttf": "ad0a28f28f736cf4c121bcb0e719b88a",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Typewriter-Regular.ttf": "87f56927f1ba726ce0591955c8b3b42d",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Caligraphic-Bold.ttf": "a9c8e437146ef63fcd6fae7cf65ca859",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_SansSerif-Italic.ttf": "d89b80e7bdd57d238eeaa80ed9a1013a",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Size1-Regular.ttf": "1e6a3368d660edc3a2fbbe72edfeaa85",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Main-Regular.ttf": "5a5766c715ee765aa1398997643f1589",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Math-BoldItalic.ttf": "946a26954ab7fbd7ea78df07795a6cbc",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_AMS-Regular.ttf": "657a5353a553777e270827bd1630e467",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Main-BoldItalic.ttf": "e3c361ea8d1c215805439ce0941a1c8d",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Main-Italic.ttf": "ac3b1882325add4f148f05db8cafd401",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Math-Italic.ttf": "a7732ecb5840a15be39e1eda377bc21d",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Script-Regular.ttf": "55d2dcd4778875a53ff09320a85a5296",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Size3-Regular.ttf": "e87212c26bb86c21eb028aba2ac53ec3",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Fraktur-Regular.ttf": "dede6f2c7dad4402fa205644391b3a94",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_Main-Bold.ttf": "9eef86c1f9efa78ab93d41a0551948f7",
"assets/packages/flutter_math_fork/lib/katex_fonts/fonts/KaTeX_SansSerif-Regular.ttf": "b5f967ed9e4933f1c3165a12fe3436df",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "ba5b4a233ccd96b811d1ffc4d0c2ca64",
"assets/packages/flutter_js/assets/js/fetch.js": "277e0c5ec36810cbe57371a4b7e26be0",
"assets/packages/flex_color_picker/assets/opacity.png": "49c4f3bcb1b25364bb4c255edcaaf5b2",
"assets/packages/flutter_inappwebview_web/assets/web/web_support.js": "ffd063c5ddbbe185f778e7e41fdceb31",
"assets/packages/fluttertoast/assets/toastify.css": "a85675050054f179444bc5ad70ffc635",
"assets/packages/fluttertoast/assets/toastify.js": "56e2c9cedd97f10e7e5f1cebd85d53e3",
"assets/packages/flutter_inappwebview/assets/t_rex_runner/t-rex.html": "16911fcc170c8af1c5457940bd0bf055",
"assets/packages/flutter_inappwebview/assets/t_rex_runner/t-rex.css": "5a8d0222407e388155d7d1395a75d5b9",
"assets/AssetManifest.bin.json": "81a7beef90032ca353de7f87217b9778",
"assets/FontManifest.json": "e8992b70c205310bdb1568e9790e27a1",
"assets/fonts/MaterialIcons-Regular.otf": "d8cacdbed193b979e601a82db2dd45f3",
"assets/AssetManifest.json": "6cd5c171f5cfb3dbb1daf7276da3af02",
"index.html": "5f6a5209523f4ccf11da71cc3f0a5324",
"/": "5f6a5209523f4ccf11da71cc3f0a5324",
"manifest.json": "012d91b9edf492757ddf24dd1b15d03e"};
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
