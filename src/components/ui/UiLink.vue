<script setup>
const props = defineProps({
  // extern is for set a RouterLink for no reload or a simple a anchor
  extern: Boolean,
  url: {
    type: String,
    required: true,
  },
  text: {
    type: String,
    required: true,
  },
});
</script>

<template>
  <div v-if="props.extern !== true">
    <RouterLink
      class="link relative mx-2 p-2 flex flex-col items-center font-medium"
      :to="props.url"
      >{{ props.text }}
    </RouterLink>
  </div>

  <a v-else :href="props.url" target="_blank">{{ props.text }}</a>
</template>

<style scoped>
/* after:block after:w-full after:h-0.5 
 after:bg-black after:transition-all hover:after:translate-x-1/2
  */

.link::after {
  content: "";
  position: absolute;
  bottom: calc(var(--spacing) * 0.5);
  width: 100%;
  height: 0.125rem;
  display: block;
  background: #000;
  animation: link-out 0.6s forwards;
}
.link:hover::after {
  animation: link-in 0.5s forwards;
  /* animation-fill-mode: forwards; */
}

.router-link-active::after {
  animation: link-in 1s forwards;
}

@keyframes link-in {
  0% {
    right: 0;
    width: 100%;
  }
  40% {
    bottom: calc(var(--spacing) * 0.4);
    width: 0.25rem;
    height: 0.125rem;
    transform: translateY(0%);
  }
  100% {
    right: 0;
    bottom: calc(var(--spacing) * 4);
    width: 0.25rem;
    height: 0.25rem;
    transform: translateY(75%);
  }
}

@keyframes link-out {
  0% {
    right: 0;
    bottom: 42%;
    width: 0.25rem;
    height: 0.25rem;
    transform: translateY(75%);
  }
  60% {
    bottom: calc(var(--spacing) * 0.4);
    width: 0.25rem;
    height: 0.125rem;
    transform: translateY(0%);
  }

  100% {
    right: 0;
    width: 100%;
  }
}
</style>
