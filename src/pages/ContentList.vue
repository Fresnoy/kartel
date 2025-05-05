<script setup>
import axios from "axios";

import config from "@/config";

import { useRouter } from "vue-router";

import { ref, computed, onMounted, watch } from "vue";

/**

  Components

**/
import {
  content as contents,
  getContent,
  load,
  resetData,
} from "@/composables/getContent";

/**

  Components

**/
import UnderlineTitle from "@/components/ui/UnderlineTitle.vue";
import ArtworkCard from "@/components/artwork/ArtworkCard.vue";
import ArtistCard from "@/components/artist/ArtistCard.vue";
import UiSelect from "@/components/ui/UiSelect.vue";

const router = useRouter();

let typeOfContent = ref();
let watcher = ref();
let hasNextPage = ref(true);
let loader = ref(true)
let observer = ref();

const component = computed(() => {
  if (typeOfContent.value === "artworks") {
    return ArtworkCard;
  } else if (typeOfContent.value === "artists") {
    return ArtistCard;
  }
});

/**
 *
 *  default value/option of refs
 *
 */
// let years = ref([]);

let defGenres = ref(null);
let defKeywords = ref(null);
let defNationality = ref(null);
let defProductionYear = ref([]);
// let defQ = ref(null);
let defShootingPlace = ref(null);
let defType = ref(null);
let defArtistsTypes = ref(null)

/**
 *
 *  refs
 *
 */
let genres = ref(null);
let keywords = ref(null);
let nationality = ref(null);
let productionYear = ref(null);
let q = ref(null);
let shootingPlace = ref(null);
let type = ref(null);
let artist_type = ref(null);


// let typeOfContent define the params and display them inside the dom with a includes or something like a dictionnary
let params = ref();

// watcher
watch([genres, keywords, productionYear, q, shootingPlace, type, artist_type], () => {

  // authorized path to execute router
  let paths = ["/artists", "/artworks"]

  // can filter only defined parameters for a cleanest URL
  if (paths.includes(router.currentRoute.value.path)) {
    router.push({ path: typeOfContent.value, query: { ...params.value } });
  }
});

// set option of production year for select based on a min (1998) to now
function getYears() {
  let max = new Date().getFullYear();
  let min = 1998;
  let number = max - (max - min);

  for (let i = max; i >= number; i--) {
    defProductionYear.value.push(i);
  }
}
getYears();

function getTypes() {
  const types = ["film", "installation", "performance"];

  const sortedTypes = types.sort((a, b) => a.localeCompare(b));

  defType.value = sortedTypes;
}
getTypes();

async function getKeywords() {
  try {
    const response = await axios.post(`${config.v3_graph}`, {
      query:
      `
      query MyQuery {
        productions {
          ... on ArtworkType {
            keywords {
              name
            }
          }
        }
      }
      `
      }, {
        headers: {
          'Content-Type': 'application/json'
        }
      }
    );

    const data = response.data.data.productions;

    //Having keywords by production
    const keywordsEntry = data.map((entry) => {
      if (entry.keywords?.length > 0) {
        return entry.keywords;
      }
    }).filter(item => item !== undefined);

    const allKeywordsName = [];

    //isolate names and push them into an array
    for (let i =0; i < keywordsEntry.length; i++) {
      for (let j =0; j < keywordsEntry[i].length; j++) {
        allKeywordsName.push(keywordsEntry[i][j].name)
      }
    }

    // remove double entries
    const keywordsNameSet = new Set(allKeywordsName)

    const keywordsName = [...keywordsNameSet]

    // sort by name
    const sortedKeywords = keywordsName.sort((a, b) => a.localeCompare(b));

    defKeywords.value = sortedKeywords;
  } catch (err) {
    console.error(err);
  }
}
getKeywords();


function getArtistsTypes() {
  const types = [
                 {name: "Étudiant",
                  value:"student"},
                 {name: "Artistes Professeurs invités",
                  value:"teacher"},
                 {name: "Scientifiques",
                  value:"scienceStudent"},
                 {name: "Artistes invités",
                  value:"visitingStudent"},
                 ];

  // const sortedTypes = types.sort((a, b) => a.localeCompare(b));

  defArtistsTypes.value = types; // sortedTypes;

}
getArtistsTypes();

// fetch a load of artworks
const fetchData = async () => {
    await getContent(typeOfContent.value, params.value);
    loader.value = false
};

async function setup() {
  // Reset page parameter in order to don't miss data
  resetData()

  // name or path to set default content
  typeOfContent.value = router.currentRoute.value.path.replace("/", "");
  contents.value = [];
  load.value = true;

  let queries = router.currentRoute.value.query;

  // set params with type
  if (typeOfContent.value === "artworks") {
    params.value = {
      productionYear,
      keywords,
      type,
    };
  } else {
    params.value = {
      nationality,
      q,
      artist_type,
    };
  }

  // set default value if present in queries
  for (let param in params.value) {
    queries[param]
      ? (params.value[param] = queries[param])
      : (params.value[param] = null);
  }

  // Need to disconnect the observer to avoid fetch duplicated data
  disconnectObserver();

  // Fetch the data
  await fetchData();

  initializeObserver();
}

// Add observer to fetch more new data if they are
const handleObserver = (entries) => {
    const target = entries[0];
    if (target.isIntersecting && hasNextPage.value) {
      fetchData();
    }
  };

  const initializeObserver = () => {
    observer.value = new IntersectionObserver(handleObserver, {
      root: null,
      rootMargin: '0px',
      threshold: 0.1
    });

    if(watcher.value) {
      observer.value.observe(watcher.value);
    }
  }

  const disconnectObserver = () => {
    if(observer.value) {
      observer.value.disconnect();
    }
  }

onMounted(() => {
  setup();
});

// refresh content when changing type (artworks, artists)
watch(
  () => router.currentRoute.value.fullPath,
  () => {
    setup();
  }
);

</script>

<template>
  <main class="pt-10 lg:pr-20 px-10 lg:px-0 w-full">
    <UnderlineTitle
      class="w-max mb-6"
      :title="typeOfContent === 'artworks' ? 'Œuvres' : 'Artistes'"
      :uppercase="true"
      :underlineSize="1"
      :fontSize="1"
    />
    <!-- fluid grid -->
    <div class="mb-6 flex items-center flex-wrap gap-6">
      <h3 class="text-lg font-medium text-gray-dark">Filtres :</h3>
      <!-- TODO need to update to a dynamic way of display filters -->
      <UiSelect
        v-if="params && Object.keys(params).includes('productionYear')"
        :options="defProductionYear"
        defaultValue="toutes dates"
        :selectedValue="productionYear"
        desc="Date de production"
        @update:option="(newValue) => (productionYear = newValue)"
      ></UiSelect>

       <UiSelect
        v-if="params && Object.keys(params).includes('artist_type')"
        :options="defArtistsTypes"
        defaultValue="aucun"
        optionKeyName="label"
        :selectedValue="artist_type"
        desc="Artiste"
        @update:option="(newValue) => (artist_type = newValue)"
      ></UiSelect>

      <UiSelect
        v-if="params && Object.keys(params).includes('keywords')"
        :options="defKeywords"
        defaultValue="aucun"
        :selectedValue="keywords"
        desc="Keywords"
        @update:option="(newValue) => (keywords = newValue)"
      ></UiSelect>

      <UiSelect
        v-if="params && Object.keys(params).includes('type')"
        :options="defType"
        defaultValue="tout type"
        :selectedValue="type"
        desc="Type"
        @update:option="(newValue) => (type = newValue)"
      ></UiSelect>

    </div>
    <span class="my-3 w-full h-0.5 block bg-gray-extralight"></span>

    <div>
      <ul
        class="pb-12 grid lg:grid-cols-fluid-14-lg grid-cols-fluid-14 grow-0 gap-3"
      >
        <li class="" v-for="content in contents" :key="content">
          <component
            :is="component"
            :artist="content"
            :id="content.id"
            :picture="content.picture"
            :title="content.title"
          ></component>
        </li>
        <span ref="watcher" id="watcher" class="block w-full h-full"></span>
      </ul>
    </div>
  </main>
</template>

<style scoped></style>
