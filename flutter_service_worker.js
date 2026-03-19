'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {".git/COMMIT_EDITMSG": "05bb8ff5ef948d3d3ed1881451d872f7",
".git/config": "8ec34dd768abdfd7d1e12639627adcbe",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/HEAD": "5ab7a4355e4c959b0c5c008f202f51ec",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/index": "676a864062df2d71205a3b499b0a06c8",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "8a5e8ca641761d04916002abcd10e67d",
".git/logs/refs/heads/gh-pages": "8a5e8ca641761d04916002abcd10e67d",
".git/logs/refs/remotes/origin/gh-pages": "02ab31daf2f3a505c6e0b1521713b17b",
".git/objects/09/daca7cf0a7eee8362646bc08ba2a0d7299b885": "b23cbd28c7b26f384a24ad51b56630e4",
".git/objects/0e/bbac2aecd2ab150e711220c8d821f0208f3963": "992aee08f92fb21e5409f1de90af0dfb",
".git/objects/1a/d7683b343914430a62157ebf451b9b2aa95cac": "94fdc36a022769ae6a8c6c98e87b3452",
".git/objects/1a/fc03ca37eecbb4d9a813c0bfdc6ee0ee2c9076": "061f306d4c5ac98ca91802f54a385ef0",
".git/objects/23/b5f3e56219180e0a98d59bf5215cb7698e43f1": "9ed2b0c804a20d17d82b76a8b1404779",
".git/objects/2f/6ecee986670a54a99c1d975cf645b7ed43c218": "e2240ac5daab37df0dad6349043229bd",
".git/objects/38/8ac6ad54bd8f3cfd8cd9ed6c2b2c814ae63b63": "cfba6976c3674688e39521b9919c69cf",
".git/objects/3b/55fcd2146a81e9e19d92b04fc355a7b9b53140": "4c9bafcedfa088a20f3f5748b1f4a9c1",
".git/objects/41/91d9e19b891e508839151251c0a8570f2ae6d5": "7fe4a06720e722908c21a08e6dfa00e6",
".git/objects/42/5d60b0ff9ed79d13d63bab773011abb4923035": "3c18d35fed323fdc117394538fda0ab2",
".git/objects/45/7ccf04a93575fb9db439c10498811eebc53498": "5910f5a13dc5b7e9890165a4cb9c8a62",
".git/objects/46/4ab5882a2234c39b1a4dbad5feba0954478155": "2e52a767dc04391de7b4d0beb32e7fc4",
".git/objects/4c/51fb2d35630595c50f37c2bf5e1ceaf14c1a1e": "a20985c22880b353a0e347c2c6382997",
".git/objects/52/dcb870d85ee3a5d3ceda07c460e1a23c2633a4": "855b0e0a0404d1fdd670122609d21be5",
".git/objects/53/18a6956a86af56edbf5d2c8fdd654bcc943e88": "a686c83ba0910f09872b90fd86a98a8f",
".git/objects/53/3d2508cc1abb665366c7c8368963561d8c24e0": "4592c949830452e9c2bb87f305940304",
".git/objects/5a/2bd809b5c664ba1fcb657f3dc94e3c179c91af": "c83dd796a28cde50fccad90c73b700ca",
".git/objects/63/0b9083aea0af7bb536ac90002a73cb793e1e0e": "c1a168b4680ffd01485a859028de5a3c",
".git/objects/6a/0464bc866e9057384fcdf70eb37308a0905779": "312269d541a7b498b5d6998e2db4db52",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "85896cd5fba127825eb58df13dfac82b",
".git/objects/70/a234a3df0f8c93b4c4742536b997bf04980585": "d95736cd43d2676a49e58b0ee61c1fb9",
".git/objects/73/c63bcf89a317ff882ba74ecb132b01c374a66f": "6ae390f0843274091d1e2838d9399c51",
".git/objects/75/eaf6a4a65a686783482579db72aa8d6bd80328": "18ea147cc9a899827ddce698cd4d5e51",
".git/objects/8b/50eafaa22d6e135a2b936de10b941b20e33c74": "e1f5dd11284bcfaf17c28268a52e9081",
".git/objects/8e/3c7d6bbbef6e7cefcdd4df877e7ed0ee4af46e": "025a3d8b84f839de674cd3567fdb7b1b",
".git/objects/9b/01e6671a306577dbbe11d45d1c71259b0855c7": "492bff5810c7b876d625eb3e126bcb85",
".git/objects/9b/d3accc7e6a1485f4b1ddfbeeaae04e67e121d8": "784f8e1966649133f308f05f2d98214f",
".git/objects/a2/50f098959afd4ef772ed64a8f8374fd5724101": "5d3d936191a6a28c67e290acb4bd27c5",
".git/objects/a9/0bd501ee5859c089cc8b96a1bafaa74f93c851": "5f29acc84d8c2adb99965b8c9e367382",
".git/objects/ad/7a2cdc1f4059db665696d5148fc4e5ebb81998": "ad8ad377c97c3ec07aeb23f9ad3ebe20",
".git/objects/af/ba81dce44b62362aa71e5b6ad2eb8d7666d0e1": "fea631ae5d62448e00facdf1473ebe51",
".git/objects/af/c87a47fd02e608943b38818f74b0eb1f1771b4": "44161b83e48dbff9beca67cde55c7823",
".git/objects/b9/6a5236065a6c0fb7193cb2bb2f538b2d7b4788": "4227e5e94459652d40710ef438055fe5",
".git/objects/c3/237f7ed557ab20ff297a2225eec85f7b844075": "30b41c22b921dfdcca3f47c1b5b18fc8",
".git/objects/c8/08fb85f7e1f0bf2055866aed144791a1409207": "92cdd8b3553e66b1f3185e40eb77684e",
".git/objects/cf/cbe614a6d2463bcf1e3458fa458e50e9cebb5e": "fb9c19bb1cc2b5084bde725c639927e6",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "3dad9b209346b1723bb2cc68e7e42a44",
".git/objects/d6/9c56691fbdb0b7efa65097c7cc1edac12a6d3e": "868ce37a3a78b0606713733248a2f579",
".git/objects/d7/7cfefdbe249b8bf90ce8244ed8fc1732fe8f73": "9c0876641083076714600718b0dab097",
".git/objects/dc/11fdb45a686de35a7f8c24f3ac5f134761b8a9": "761c08dfe3c67fe7f31a98f6e2be3c9c",
".git/objects/e0/7ac7b837115a3d31ed52874a73bd277791e6bf": "74ebcb23eb10724ed101c9ff99cfa39f",
".git/objects/e6/9de29bb2d1d6434b8b29ae775ad8c2e48c5391": "c70c34cbeefd40e7c0149b7a0c2c64c2",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "2eed33506ed70a5848a0b06f5b754f2c",
".git/objects/e9/c95a1a76181a328dd98b7a7aa3f360d2a1a41d": "cffd26ff67eea1d3d4c40df5115831b0",
".git/objects/eb/9b4d76e525556d5d89141648c724331630325d": "37c0954235cbe27c4d93e74fe9a578ef",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "6b47f314ffc35cf6a1ced3208ecc857d",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "e68f5265f0bb82d792ff536dcb99d803",
".git/objects/fd/953f822e13a600daca94c81fdae47e44082cb2": "0a4fd0fdb4e37dabe063e98ad747cc97",
".git/refs/heads/gh-pages": "d3595626a25fcd4ce0125d7bb22ba4ed",
".git/refs/remotes/origin/gh-pages": "d3595626a25fcd4ce0125d7bb22ba4ed",
"assets/AssetManifest.bin": "0521dda6dd37e9ec1978ede3041c274b",
"assets/AssetManifest.bin.json": "3c8719a4394ec3b2a36762ca5c71d75f",
"assets/AssetManifest.json": "b1aff0936e65ded2f834beb855bec490",
"assets/assets/images/developer.jpeg": "26cb1a392bb9b6f77efb663e32b50c48",
"assets/assets/images/icon.png": "f3c77dc53e21bc95826709d2c81bf320",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/fonts/MaterialIcons-Regular.otf": "066d3c9e7e95996f29ad04d7160ac695",
"assets/NOTICES": "4360bd638e684394baaf0f2f4a9f2471",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"favicon.png": "f3c77dc53e21bc95826709d2c81bf320",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"flutter_bootstrap.js": "355001e59b6d99c99cae93ef33d2d60a",
"icons/Icon-192.png": "f3c77dc53e21bc95826709d2c81bf320",
"icons/Icon-512.png": "f3c77dc53e21bc95826709d2c81bf320",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "46ebd945b3d68716d93473f592b9276d",
"/": "46ebd945b3d68716d93473f592b9276d",
"main.dart.js": "f0ba2acae601255c69693d08ca16253b",
"manifest.json": "e22610299a1681df4aa0db82b85d8544",
"version.json": "a593e9914addf2dae29869173c91bf9d"};
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
