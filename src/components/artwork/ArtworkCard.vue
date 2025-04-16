<script setup>
import config from "../../config";

import mediaPlaceholder from "@/assets/placeholder_media.svg";

// define props like url of img media and url artwork

// Condition if id is alone refetch artwork info
const props = defineProps({
  picture: {
    required: true,
  },
  title: {
    type: String,
    required: true,
  },
});
</script>

<!-- Change the name with MediaCard might be better for reuse -->
<!-- set for img if preview but it can be a video watch out -->
<template>
  <router-link
    :to="`/artwork/${props.id}`"
    class="flex flex-col items-end"
  >
    <div
      :class="{ 'ring-8': props.index === 1 }"
      class="w-full aspect-video object-cover bg-gray-extralightest"
    >
      <img
        class="w-full object-cover aspect-video"
        :alt="props.title"
        :src="
          props.picture
            ? `${config.media_service}?url=https://api.lefresnoy.net/media/${props.picture}&mode=adapt&w=300&fmt=jpg`
            : mediaPlaceholder
        "
      />
    </div>
    <span class="block w-full h-1 bg-black"></span>
    <h6 class="text-xs text-gray font-medium uppercase">{{ props.title }}</h6>
  </router-link>
</template>

<style scoped></style>
