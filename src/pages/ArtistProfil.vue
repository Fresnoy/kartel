<script setup>
import config from "@/config";
import { useRouter } from "vue-router";

import { ref, onMounted, onBeforeUnmount, watch, computed } from "vue";

import { marked } from "marked";

/**
 * Modules
 */
import { Fancybox } from "@fancyapps/ui";
import "@fancyapps/ui/dist/fancybox/fancybox.css";

/**
  Composables
**/
import {
  artist,
  setup,
} from "@/composables/artist/getArtistInfo";

/**
  Components
**/
import UnderlineTitle from "@/components/ui/UnderlineTitle.vue";
import UiDescription from "@/components/ui/UiDescription.vue";
import ArtworkCard from "@/components/artwork/ArtworkCard.vue";

import userPlaceholder from "@/assets/placeholder_user.svg";

const router = useRouter();

let artistId = router.currentRoute.value.params.id;

let token = localStorage.getItem("token") || false;

let responsive = ref(false);

/**
 * Détermine le type de profil (Solo, Duo, Trio, Collectif)
 */
const artistTypeLabel = computed(() => {
  if (!artist.value?.collectives || artist.value.collectives.length === 0) {
    return "Artiste Solo";
  }
  const count = artist.value.collectives.length;
  if (count === 2) return "Duo d'artistes";
  if (count === 3) return "Trio d'artistes";
  return `Collectif (${count} membres)`;
});

const formatSocialNumber = (number) => {
  const socialNumberRegex =
    /\S{1}\s{1}\S{2}\s{1}\S{2}\s{1}\S{2}\s{1}\S{3}\s{1}\S{3}\s{1}\S{2}/gm;

  if (number.match(socialNumberRegex)) {
    return number;
  }

  number = number.toString().split("");

  const spaces = ["1", "4", "7", "10", "14", "18"];

  for (let space of spaces) {
    number.splice(space, 0, " ");
  }

  return number.toString().replaceAll(",", "");
};

const formatDomain = (url) => {
  if (!url) return '';
  try {
    const validUrl = url.includes('://') ? url : `http://${url}`;
    const hostname = new URL(validUrl).hostname;
    return hostname.replace(/^www\./, '');
  } catch {
    return url;
  }
};

/**
 * parsed raw description from markdown or html (or both) and parse it
 * @param {string} content - desc from props via bio.data
 */
function parsedContent(content) {
  return marked(content);
}

function formatUrlToText(url) {
  const filenameRegex = /\S{0,}[.]\S{0,}/gm;
  const split = url.split("/");

  if (!!split[split.length - 1].match(filenameRegex)) {
    return split[split.length - 1];
  }

  return url;
}

let preview = ref();

onMounted(() => {
  setup(artistId, token);
  Fancybox.bind(preview.value, "[data-fancybox]");
});

onBeforeUnmount(() => {
  Fancybox.destroy();
});

const routeName = router.currentRoute.value.name;
watch(
  () => router.currentRoute.value.path,
  () => {
    if (router.currentRoute.value.name !== routeName) {
      return;
    }

    artistId = router.currentRoute.value.params.id;
    setup(artistId, token);
    Fancybox.bind("[data-fancybox]");
  }
);
</script>

<template>
  <main
    class="lg:pr-20 w-full min-h-screen flex flex-col gap-1 lg:gap-5 divide-y lg:divide-y-0"
  >
    <!-- Navigation mobile responsive -->
    <div
      class="sticky z-10 top-14 w-full flex justify-around lg:hidden divide-x bg-white"
    >
      <a
        href="#content"
        @click="responsive = false"
        class="px-6 py-3 w-full text-xl font-bold hover:bg-gray-extralightest after:block after:w-full after:h-1 after:bg-black cursor-pointer"
        :class="{ 'bg-gray-extralightest': responsive === false }"
      >
        À propos
      </a>
      <a
        href="#artwork"
        @click="responsive = true"
        class="px-6 py-3 w-full text-xl font-bold hover:bg-gray-extralightest after:block after:w-full after:h-1 after:bg-black cursor-pointer"
        :class="{ 'bg-gray-extralightest': responsive === true }"
      >
        Média
      </a>
    </div>

    <div
      class="pb-2 w-full min-h-screen flex flex-col lg:flex-row justify-between gap-10 divide-x"
    >
      <div class="pl-8 pr-6 pt-5 pb-12 lg:w-3/5 flex flex-col">
        <div id="content" class="flex flex-col gap-10">
          
          <!-- En-tête : Photo et Nom -->
          <div class="flex flex-col lg:flex-row lg:items-end gap-6">
            <div class="relative w-fit h-full flex">
              <img
                v-if="artist?.displayPhoto"
                class="min-h-[300px] bg-black-extralightest object-cover"
                :class="{ 'p-5': !artist?.displayPhoto }"
                :src="
                  artist?.displayPhoto
                    ? `${config.media_service}?url=${config.api_media_url}${artist?.displayPhoto}&w=300&h=300&mode=clip&fmt=jpg`
                    : userPlaceholder
                "
                :alt="`Photo de ${artist.displayName}`"
              />
              
              <svg
                v-if="artist?.student?.graduate"
                class="absolute top-0 right-0 translate-x-1/2 -translate-y-1/2 w-6"
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 24 24"
              >
                <path
                  d="M12 2L0 9L12 16L22 10.1667V17.5H24V9L12 2Z M3.99902 13.4905V18.0001C5.82344 20.429 8.72812 22.0001 11.9998 22.0001C15.2714 22.0001 18.1761 20.429 20.0005 18.0001L20.0001 13.4913L12.0003 18.1579L3.99902 13.4905Z"
                ></path>
              </svg>
            </div>

            <div v-if="artist" class="w-2/3 flex flex-col gap-2">
              <!-- Badge du type d'artiste (Solo / Duo / Trio / Collectif) -->
              <span class="px-2.5 py-1 text-xs font-semibold bg-gray-100 text-gray-800 rounded-md w-fit border border-gray-200">
                {{ artistTypeLabel }}
              </span>

              <UnderlineTitle
                class="w-max"
                v-if="artist?.displayName"
                :title="`${artist.displayName}`"
                subtitle="Artist"
                :uppercase="true"
                :underlineSize="1"
                :fontSize="2"
              ></UnderlineTitle>

              <UnderlineTitle
                class="w-max"
                v-else
                title="Nom manquant"
                subtitle="Artist"
                :uppercase="true"
                :underlineSize="1"
                :fontSize="2"
              ></UnderlineTitle>

              <h4 v-if="artist?.student?.promotion?.name">
                Promotion
                <router-link
                  :to="`/school/promotion/${artist.student.promotion.id}`"
                  class="underline"
                >
                  {{ artist.student.promotion.name }}
                </router-link>
              </h4>
            </div>
          </div>

          <!-- Sites et liens -->
          <div
            v-if="artist?.websites && artist?.websites.length !== 0"
            class="flex flex-col gap-3"
          >
            <UnderlineTitle
              class="w-max"
              title="Sites et liens"
              :uppercase="true"
              :underlineSize="1"
              :fontSize="2"
            />

            <ul class="flex flex-row gap-1">
              <li class="flex gap-1" v-for="(website, index) in artist.websites" :key="website.id">
                <a :href="website.url" class="underline" target="_blank">
                  {{ formatDomain(website.url) }} 
                </a>
                <span v-if="index != artist.websites.length - 1"> - </span> 
              </li>
            </ul>
          </div>

          <!-- Section Contacts & Administratif & Autres infos (Affiché si token présent) -->
          <div v-if="token && artist" class="flex flex-wrap gap-8">

            <!-- CONTACTS PAR MEMBRE -->
            <div class="flex flex-col gap-4 flex-[1_1_22rem]">
              <UnderlineTitle
                class="w-max"
                title="Contact & Informations"
                :uppercase="true"
                :underlineSize="1"
                :fontSize="2"
              />
              
              <!-- Boucle propre par membre (collectif ou artiste solo) -->
              <div 
                v-for="(member, idx) in (artist?.collectives?.length > 0 ? artist.collectives : [artist])" 
                :key="member.id || idx"
                class="flex flex-col gap-3 p-4 bg-gray-extralightest rounded-lg border border-gray-200"
              >
                <!-- En-tête du membre si duo/trio -->
                <div v-if="artist?.collectives?.length > 0" class="border-b pb-2 mb-1">
                  <span class="text-xs font-bold uppercase tracking-wider text-gray-500">Membre {{ idx + 1 }}</span>
                  <h4 class="font-bold text-base">{{ member.displayName || `${member.firstName || ''} ${member.lastName || ''}`.trim() || 'Membre sans nom' }}</h4>
                </div>

                <ul class="flex flex-col gap-2 text-sm">
                  <li class="flex flex-wrap gap-1">
                    <b>Pseudonyme :</b>
                    <p v-if="member.nickname">{{ member.nickname }}</p>
                    <p v-else class="text-gray italic">Non renseigné.</p>
                  </li>

                  <li class="flex flex-col">
                    <div class="flex gap-1">
                      <b>Nom :</b>
                      <p>{{ member.lastName || 'Non renseigné' }}</p>
                    </div>
                    <div class="flex gap-1">
                      <b>Prénom :</b>
                      <p>{{ member.firstName || 'Non renseigné' }}</p>
                    </div>
                  </li>

                  <li v-if="member?.user?.profile?.preferredLastName || member?.user?.profile?.preferredFirstName" class="flex flex-col">
                    <div class="flex gap-1">
                      <b>Nom d'usage :</b>
                      <p>{{ member.user.profile.preferredLastName }}</p>
                    </div>
                    <div class="flex gap-1">
                      <b>Prénom d'usage :</b>
                      <p>{{ member.user.profile.preferredFirstName }}</p>
                    </div>
                  </li>

                  <li class="flex flex-wrap gap-1">
                    <b>Nationalité :</b>
                    <p v-if="member?.nationality || member?.homelandCountry">
                      {{ member?.nationality || member?.homelandCountry }}
                    </p>
                    <p v-else class="text-gray italic">Non renseigné.</p>
                  </li>

                  <li class="flex flex-wrap gap-1">
                    <b>Tel :</b>
                    <p v-if="member?.residencePhone || member?.homelandPhone">
                      {{ member?.residencePhone || member?.homelandPhone }}
                    </p>
                    <p v-else class="text-gray italic">Non renseigné.</p>
                  </li>

                  <li class="flex flex-wrap gap-1">
                    <b>Date de naissance :</b>
                    <p v-if="member?.birthdate">
                      {{ new Date(member.birthdate).toLocaleDateString('fr-FR', { year: 'numeric', month: 'long', day: 'numeric' }) }} 
                      ({{ new Date().getFullYear() - new Date(member.birthdate).getFullYear() }} ans)
                    </p>
                    <p v-else class="text-gray italic">Non renseigné.</p>
                  </li>

                  <li class="flex flex-wrap gap-1">
                    <b>E-Mail :</b>
                    <p v-if="member?.user?.email">{{ member.user.email }}</p>
                    <p v-else class="text-gray italic">Non renseigné.</p>
                  </li>
                </ul>
              </div>

              <!-- Section Administrative -->
              <div class="mt-4 flex flex-col gap-3">
                <UnderlineTitle
                  class="w-max mb-2"
                  title="Administratif"
                  :uppercase="true"
                  :underlineSize="1"
                  :fontSize="4"
                />
                <ul class="flex flex-col gap-2 text-sm">
                  <li class="flex flex-wrap gap-1 items-center">
                    <div v-if="artist?.student?.graduate">
                      <b>Diplômé, </b>
                      <span class="italic" v-if="artist?.student?.diplomaMention">
                        Mention {{ artist?.student?.diplomaMention }}
                      </span>
                      <a v-if="artist?.student?.diplomaFile" :href="`${config.api_media_url}${artist?.student?.diplomaFile}`" target="_blank" class="ml-1 underline text-blue-600">↗ Voir diplôme</a>
                      <a v-else class="text-gray italic underline ml-1" :href="`${config.api_url}admin/school/student/${artist?.student?.id}/`" target="_blank">
                        Ajouter le diplôme
                      </a>
                    </div>
                    <div v-else>
                      <a class="italic underline" :href="`${config.api_url}admin/school/student/${artist?.student?.id}/`" target="_blank">
                        Non diplômé ✎
                      </a>
                    </div>
                  </li>

                  <div v-if="artist.artworks" class="flex flex-col gap-2 mt-2">
                    <li v-for="artwork in artist?.artworks" :key="artwork.id">
                      <div class="flex flex-wrap gap-1 items-center">
                        <b>Contrat de production {{ artwork.productionDate ? artwork.productionDate.split("-")[0] : '' }} :</b>
                        <a
                          v-if="artwork?.productionContract"
                          :href="`${config.api_media_url}${artwork?.productionContract}`"
                          class="underline"
                          data-fancybox="preview"
                        >
                          {{ formatUrlToText(artwork?.productionContract) }}
                        </a>
                        <p v-else class="text-gray italic">
                          <a class="underline" :href="`${config.api_url}admin/production/artwork/${artwork.id}/#id_production_contract`" target="_blank">
                            Non renseigné ＋
                          </a>
                        </p>
                      </div>
                    </li>
                  </div>
                </ul>
              </div>
            </div>

            <!-- AUTRES INFORMATIONS & CANDIDATURES -->
            <div class="flex flex-col gap-4 flex-[1_1_22rem] break-all" v-if="artist.studentApplication || artist.collectives[0]?.studentApplication[0] ">
              <UnderlineTitle
                class="w-max"
                title="Autres informations & Candidature"
                :uppercase="true"
                :underlineSize="1"
                :fontSize="2"
              />

              <!-- Boucle propre par membre pour les pièces et candidatures -->
              <div 
                v-for="(member, idx) in (artist?.collectives?.length > 0 ? artist.collectives : [artist])" 
                :key="member.id || idx"
                class="flex flex-col gap-3 p-4 bg-gray-extralightest rounded-lg border border-gray-200"
                :set="candidature = member?.studentApplication?.[member.studentApplication.length - 1] ?? null"
              >
                <!-- En-tête du membre si duo/trio -->
                <div v-if="artist?.collectives?.length > 0" class="border-b pb-2 mb-1">
                  <span class="text-xs font-bold uppercase tracking-wider text-gray-500">Candidature / Dossier - Membre {{ idx + 1 }}</span>
                  <h4 class="font-bold text-base">{{ member.displayName || `${member.firstName || ''} ${member.lastName || ''}`.trim() || 'Membre sans nom' }}</h4>
                </div>

                <ul class="flex flex-col gap-2 text-sm">
                  <li class="flex flex-wrap gap-1">
                    <b>CV :</b>
                    <a
                      v-if="candidature?.curriculumVitae"
                      :href="`${config.api_media_url}${candidature?.curriculumVitae}`"
                      class="underline"
                      data-fancybox="preview"
                    >
                      {{ formatUrlToText(candidature?.curriculumVitae) }}
                    </a>
                    <p v-else class="text-gray italic">Non renseigné.</p>
                  </li>
                  
                  <li class="flex flex-wrap gap-1">
                    <b>Justificatif d'identité :</b>
                    <a
                      v-if="candidature?.identityCard"
                      :href="`${config.api_media_url}${candidature?.identityCard}`"
                      class="underline"
                      data-fancybox="preview"
                    >
                      {{ formatUrlToText(candidature?.identityCard) }}
                    </a>
                    <p v-else class="text-gray italic">Non renseigné.</p>
                  </li>

                  <div class="mt-2 pt-2 border-t border-gray-200">
                    <span class="font-bold text-xs uppercase text-gray-600 block mb-2">Dans le cadre de sa candidature :</span>
                  </div>

                  <li class="flex flex-wrap gap-1">
                    <b>Proposition initiale :</b>
                    <span v-if="candidature?.consideredProject1 || candidature?.consideredProject2" class="flex gap-1">
                      <a
                        v-if="candidature?.consideredProject1"
                        :href="`${config.api_media_url}${candidature?.consideredProject1}`"
                        class="underline"
                        data-fancybox="preview"
                      >
                        1<sup>ère</sup> année
                      </a>
                      <span v-if="candidature?.consideredProject1 && candidature?.consideredProject2">/</span>
                      <a
                        v-if="candidature?.consideredProject2"
                        :href="`${config.api_media_url}${candidature?.consideredProject2}`"
                        class="underline"
                        data-fancybox="preview"
                      >
                        2<sup>ème</sup> année
                      </a>
                    </span>
                    <p v-else class="text-gray italic">Non renseigné.</p>
                  </li>

                  <li class="flex flex-wrap gap-1">
                    <b>Document libre :</b>
                    <a
                      v-if="candidature?.freeDocument"
                      :href="`${config.api_media_url}${candidature?.freeDocument}`"
                      class="underline"
                      data-fancybox="preview"
                    >
                      {{ formatUrlToText(candidature?.freeDocument) }}
                    </a>
                    <p v-else class="text-gray italic">Non renseigné.</p>
                  </li>

                  <li class="flex flex-wrap gap-1">
                    <b>Vidéo de présentation :</b>
                    <a
                      v-if="candidature?.presentationVideo"
                      :href="candidature?.presentationVideo.includes('vimeo') ? 
                        `https://vimeo.com/${candidature?.presentationVideo.split('/').reverse()[0]}` 
                        : candidature?.presentationVideo"
                      class="underline"
                      data-fancybox="preview"
                    >
                      {{ formatUrlToText(candidature?.presentationVideo) }}
                    </a>
                    <p v-else class="text-gray italic">Non renseigné.</p>
                  </li>
                </ul>
              </div>
            </div>

            <!-- CURSUS -->
            <div class="w-full flex flex-col gap-3">
              <details class="group peer">
                <summary
                  class="group relative flex items-center gap-3 cursor-pointer"
                >
                  <UnderlineTitle
                    title="Cursus"
                    :underlineSize="1"
                    :fontSize="2"
                  />
                  <div
                    v-if="artist?.cursus"
                    class="relative w-5 h-5 border-0.5 border-gray rounded-sm"
                  >
                    <span
                      class="absolute inset-x-1/2 inset-y-1/2 -translate-x-1/2 -translate-y-1/2 block w-3 h-px bg-gray"
                    ></span>
                    <span
                      class="group-open:rotate-90 absolute inset-x-1/2 inset-y-1/2 -translate-x-1/2 -translate-y-1/2 block w-px h-3 bg-gray transition-all"
                    ></span>
                  </div>
                </summary>
              </details>

              <div
                class="relative max-h-52 peer-open:max-h-full peer-open:after:hidden overflow-hidden"
                :class="{
                  'after:block after:absolute after:bottom-0 after:w-full after:h-1/2 after:bg-linear-to-t after:from-white after:to-transparent after:pointer-events-none':
                  artist?.cursus,
                }"
              >
                <p
                  v-if="artist?.cursus"
                  class="text-sm whitespace-pre-line *:whitespace-pre-line"
                  v-html="parsedContent(artist?.cursus)"
                ></p>
                <p v-else class="text-gray italic">Non renseigné.</p>
              </div>
            </div>
          </div>
          <UnderlineTitle
                    title="Biographie"
                    :underlineSize="1"
                    :fontSize="2"
                  />
          <UiDescription
            v-if="artist?.bioFr || artist?.bioEn"
            :desc_fr="artist.bioFr"
            :desc_en="artist.bioEn"
            
          />
        </div>
      </div>

      <!-- Colonne des œuvres (Artwork) -->
      <div
        v-if="artist?.artworks"
        id="artwork"
        class="pl-8 pr-6 py-5 sticky top-20 w-full lg:w-2/5 lg:h-[90svh] lg:overflow-y-auto flex flex-col gap-6"
      >
        <div class="lg:hidden flex flex-col">
          <hr />
          <UnderlineTitle
            class="w-max"
            title="Galleries"
            :uppercase="true"
            :underlineSize="1"
            :fontSize="1"
          />
        </div>

        <UnderlineTitle
          class="w-max"
          title="Œuvres"
          subtitle="Artist"
          :uppercase="true"
          :underlineSize="1"
          :fontSize="2"
        />
        <ul class="grid grid-cols-2 gap-3">
          <li v-for="artwork in artist?.artworks" :key="artwork.id">
            <ArtworkCard
              :id="artwork.id"
              :picture="artwork.picture"
              :title="artwork.title"
            />
          </li>
        </ul>
      </div>
    </div>
  </main>
</template>

<style scoped></style>