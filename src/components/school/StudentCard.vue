<script setup>
import config from "@/config";

import { computed } from "vue";

import userPlaceholder from "@/assets/placeholder_user.svg";
import { getId } from "@/composables/getId";

const props = defineProps({
  student: Object,
});

const fullname = computed(() => {
  return props.student.artistData.nickname != "" ? 
         `${props.student.artistData.nickname}`:
         `${props.student.userData.firstName} ${props.student.userData.lastName}`;
});
</script>

<template>
  <li class="bg-white">
    <div
      v-if="props.student.userData"
      class="relative h-full border-solid border-2 border-gray hover:border-black dark:hover:border-gray-extralightest"
      :key="props.student.userData.id"
    >
      <router-link :to="`/artist/${props.student.artist.id}`">
        <img
          class="w-full h-44 bg-gray-extralightest"
          :class="{
            'object-cover': props.student?.userData?.photo,
            'p-4': !props.student?.userData?.photo,
          }"
          :src="
           props.student?.userData?.photo
              ? `${config.media_service}?url=https://api.lefresnoy.net/media/${props.student.userData.photo}&mode=adapt&w=300&fmt=jpg`
              : userPlaceholder
          "
          :alt="`Photo de ${fullname}`"
        />
        <div v-if="props.student.artistData?.nickname" class="p-2 w-full capitalize">
          <p class="last:font-bold">
            {{ fullname }}
          </p>
        </div>
        <div v-else class="p-2 w-full capitalize">
          {{ fullname }}
          <p v-if="props.student.userData.firstName" class="last:font-bold">
            {{ props.student.userData.firstName }}
          </p>
          <p v-if="props.student.userData.lastName" class="last:font-bold">
            {{ props.student.userData.lastName }}
          </p>
        </div>
      </router-link>
    </div>
  </li>
</template>

<style scoped></style>
