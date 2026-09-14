<script setup>
import config from "@/config";

import { useRouter } from "vue-router";
import { getId } from "@/composables/getId";
import { ref, onMounted } from "vue";

import UnderlineTitle from "@/components/ui/UnderlineTitle.vue";
import UiDescription from "@/components/ui/UiDescription.vue";
import ArtworkCard from "@/components/artwork/ArtworkCard.vue";
import axios from "axios";

const router = useRouter();

let staff = ref();

onMounted(() => {
  const staffId = router.currentRoute.value.params.id;
  // can combine both function with more function parameters...
  async function getStaff(id) {
    let response = await axios.post(`${config.v3_graph}`, {
      query: `
      query {
        staff(id: ${id}) {
            id
            user {
                displayName
            }
            tasks {
                id
                taskName
                production {
                    id
                    productionDate
                    title
                    picture
                }
            }
        }
      }
      `
    }, {
      headers: {
        'Content-Type': 'application/json'
      }
    });
    
    let data = await response.data.data.staff;

    staff.value = data;
    // group productions with same task name
    let groupedTasks = {};
    for (let task of staff.value.tasks) {
      if (!groupedTasks[task.taskName]) {
        groupedTasks[task.taskName] = [];
      }
      groupedTasks[task.taskName].push(task.production);
    }
    staff.value.groupedTasks = groupedTasks;
  }

  getStaff(staffId);
});




</script>

<template>
   <main class="lg:pr-20 w-full min-h-screen flex flex-col gap-1 lg:gap-5 divide-y lg:divide-y-0">

    <div class="pb-2 w-full min-h-screen flex flex-col lg:flex-row justify-between gap-10 divide-x" >
        <div class="pl-8 pr-6 pt-5 pb-12 lg:w-3/5 flex flex-col">
            <div v-if="staff" class="w-2/3 flex flex-col">
                <!-- <h4 v-if="user?.profile?.nationality" class="font-medium">
                    {{ user.profile.nationality }}
                </h4> -->
                <UnderlineTitle
                    class="w-max"
                    v-if="staff?.user?.displayName"
                    :title="`${staff.user.displayName}`"
                    :uppercase="true"
                    :underlineSize="1"
                    :fontSize="2"
                ></UnderlineTitle>
        
                <div v-if="staff?.tasks?.length > 0" class="flex flex-col gap-3 mt-6">
                    <h2 class="text-lg font-bold">Métiers</h2>
                    <p>Dans le contexte de la création des œuvres du Fresnoy</p>
                    <ul class="flex flex-col gap-5">
                        <li v-for="key, task in staff.groupedTasks"   class="pl-2 flex flex-col gap-1">
                        <p class="text-base font-bold text-grey-dark text-xl"> — {{ task }}</p>
                        <ul class="pl-6 flex flex-col gap-2">
                            <li v-for="production in staff.groupedTasks[task]" :key="production.id" class="flex flex-row gap-2 items-center">
                                <span class="text-sm font-bold">{{ production.productionDate.slice(0, 4) }} </span>
                                <router-link :to="`/artwork/${production.id}`" class="hover:underline">                                 
                                  <img class="object-cover" 
                                                        :src="production.picture ? `${config.media_service}?url=${config.api_media_url}${production.picture}&mode=adapt&h=50&w=75&mode=crop&fmt=jpg` : ''" />
                                </router-link>
                                <router-link :to="`/artwork/${production.id}`" class="hover:underline text-l font-bold">                                 
                                    {{ production.title }}
                                </router-link>
                            </li>
                        </ul>
                        </li>
                    </ul>
                </div>
            </div>
        </div>
    </div>
</main>
</template>