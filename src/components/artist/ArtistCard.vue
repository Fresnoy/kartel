<script setup>
import config from "@/config";

import { computed } from "vue";

import userPlaceholder from "@/assets/placeholder_user.svg";

const props = defineProps({
  artist: Object,
});

const fullname = computed(() => {  
  return props.artist.displayName != "" ?
          `${props.artist.displayName}`:
          "Nom manquant";
});
</script>

<template>
  <div
    v-if="props.artist"
    class="relative h-full border-solid border-2 border-gray hover:border-black dark:hover:border-gray-extralightest"
    :key="props.artist"
  >
    <!-- parameters Query with id Student ? User ? Artist ? all ? -->
    <router-link
      :to="`/artist/${props.artist.id}`"
      class="h-full flex flex-col justify-between"
    >
      <div class="w-full h-44">
        <img v-if="props.artist?.artistPhoto"
          class="w-full h-44 bg-gray-extralightest"
          :class="{
            'object-cover': props.artist?.artistPhoto,
            'p-2': !props.artist?.artistPhoto,
          }"
          :src="
            `${config.media_service}?url=${config.api_media_url}${props.artist.artistPhoto}&mode=adapt&w=300&fmt=jpg`
          "
          :alt="`Photo de ${fullname}`"
        />
        <img v-else
          class="w-full h-44 bg-gray-extralightest"
          :class="{
            'object-cover': props.artist?.photo,
            'p-2': !props.artist?.photo,
          }"
          :src="
            props.artist?.photo
              ? `${config.media_service}?url=${config.api_media_url}${props.artist.photo}&mode=adapt&w=300&fmt=jpg`
              : userPlaceholder
          "
          :alt="`Photo de ${fullname}`"
        />
        <!-- Lorem photo ? -->
      </div>
      <div class="p-2 w-full capitalize">
        <p class="last:font-bold">
          {{ fullname }}
        </p>
      </div>
    </router-link>
  </div>
</template>

<style scoped></style>
