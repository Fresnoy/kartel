<script setup>
// import config from "@/config";
import config from "@/config";

import mediaPlaceholder from "@/assets/placeholder_media.svg";
import mediaPlaceholderDoc from "@/assets/placeholder_media_document.svg";
import mediaPlaceholderSound from "@/assets/placeholder_media_sound.svg";
import mediaPlaceholderVideo from "@/assets/placeholder_media_video.svg";

const props = defineProps({
  url: {
    required: true,
  },
  // medium is the media to display in lightbox
  medium: {
    required: false,
  },
  title: {
    required: false,
  },
});
/**
 * Determine the type of medium based on props.medium and props.url.
 * @returns {string|null} - Returns "iframe" if the medium is a soundcloud link, "pdf" if the url is a pdf, and null if neither.
 */

function type() {
  const item = props.medium
    ? props.medium
    : `${config.media_service}?url=${config.api_media_url}${props.url}&mode=adapt&w=1000&fmt=jpg`;

  if (item.includes("soundcloud")) {
    return "iframe";
  }

  if (item.includes("vimeo")) {
    return "iframe";
  }

  if (item.includes(".pdf")) {
    return "pdf";
  }

  return null;
}

function getPlaceHolder(str) {
  const audioType = ["soundcloud", "mp3", "wav", "ogg"];
  const videoType = ["vimeo", "mp4", "mpeg4"];
  const documentType = ["pdf", "doc"];
  const value = str?.toLowerCase() ?? "";

  console.log("placeHolader", str)

  if (audioType.some((type) => value.includes(type))) {
    return mediaPlaceholderSound;
  }
  if (videoType.some((type) => value.includes(type))) {
    return mediaPlaceholderVideo;
  }
  if (documentType.some((type) => value.includes(type))) {
    return mediaPlaceholderDoc;
  }

  return mediaPlaceholder;
}

function resizeMedia(width){
  return `${config.media_service}?url=${config.api_media_url}${props.url}&mode=adapt&w=${width}&fmt=jpg`
}

function rewriteMedia(url){
  if(url.includes("soundcloud") && !url.includes("url=") ){
    return "https://w.soundcloud.com/player/?url="+url
  }

  return url

}

</script>

<!-- Change the name with MediaCard might be better for reuse -->
<!-- set for img if preview but it can be a video watch out -->
<template>
  <div class="flex flex-col items-end">
    <div
      @click="open = true"
      class="w-full aspect-video object-cover bg-gray-extralightest cursor-pointer"
    >
      <a
        data-fancybox="gallery"
        :data-type="type()"
        :data-caption="props.title"
        :data-height="200"
        :data-src="props.medium ? rewriteMedia(props.medium) : resizeMedia(1000)"
      >
        <img
          class="w-full h-full object-cover aspect-video"
          :src="
            props.url
              ? resizeMedia(300)
              : getPlaceHolder(props.medium)
          "
          :alt="props.title"
        />
      </a>
    </div>
    <span class="block w-full h-1 bg-black"></span>
    <h6 class="text-xs text-gray font-medium uppercase">{{ props.title }}</h6>
  </div>
</template>

<style scoped></style>
