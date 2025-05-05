<script setup>
import UnderlineTitle from "@/components/ui/UnderlineTitle.vue";
import UiDescription from "@/components/ui/UiDescription.vue";
import { ref, onMounted } from "vue";

// const props = defineProps(["artwork"]);
const props = defineProps([
  "collaborators",
  "partners",
  "creditsFr",
  "creditsEn",
]);

/**
 * this function group collaborators by task and group task when group of people are the same
 * @returns {array} Return collaborators sorted array
 */
const sortCollaborators = () => {
  if(!props.collaborators || props.collaborators.length === 0) {
    return [];
  }

  //Create a set of collaborators tasks
  const collaboratorTasks = [...new Set(props.collaborators.map(collaborator => collaborator.taskName))];

  //group collaborators by task
  const results = collaboratorTasks.map(taskName => ({
    [taskName]: props.collaborators
      .filter(collaborator => collaborator.taskName === taskName)
      .map(collaborator => collaborator.staffName)
  }));

  // Initialize new array with a first pair of task, collaborator's name
  let sortedResults = [{ ...results[0] }];

  // group tasks when group of people are the same
  for(let result of results) {
    let regex = new RegExp(`\\b${Object.keys(result)[0]}\\b`, 'i');
    let newContent = "";
    let regexNewContent = new RegExp(`\\b${Object.keys(newContent)[0]}\\b`, 'i');

    for (let sortedResult of sortedResults) {
      // When group of people are the same, but the task isn't present yet in th sorted array
      // group the tasks names and end this loop turn
      if(sortedResult !== result && !regex.test(Object.keys(sortedResult)[0]) && Object.values(sortedResult)[0][0] === Object.values(result)[0][0]) {
        let oldKey = Object.keys(sortedResult)[0];
        let newKey = `${Object.keys(sortedResult)[0]}, ${Object.keys(result)[0]}`;
        sortedResult[newKey] = sortedResult[oldKey];
        delete sortedResult[oldKey];
        break;
      }
      // if it's a new task with a new group of people, fill newContent
      if(newContent !== result && Object.values(sortedResult)[0][0] !== Object.values(result)[0][0] && !regex.test(Object.keys(sortedResult)[0])) {
        newContent = { ...result };
      }
      // reinitialize newContent if present in the other occurences of sortedResult
      if(newContent !=="" && regexNewContent.test(Object.keys(sortedResult)[0]) && Object.values(sortedResult)[0][0] === Object.values(newContent)[0][0]) {
        newContent = "";
      }
    }
    if (newContent !== "") {
      sortedResults.push(newContent);
    }
  }  
  return sortedResults;
}
</script>

<template>
  <div class="flex flex-col gap-6">
    <UiDescription
      v-if="props.creditsFr || props.creditsEn"
      :desc_fr="props.creditsFr"
      :desc_en="props.creditsEn"
    />
    <ul v-if="sortCollaborators()[0]" class="flex flex-col gap-3">
      <UnderlineTitle title="Collaborateurs" :fontSize="3" />
      <li
        v-for="collaborator in sortCollaborators()"
        :key="collaborator"
        class="flex flex-col gap-3"
      >
        <h4
          class="text-lg font-medium after:block after:w-20 after:h-1 after:bg-black"
        >
          {{ Object.values(collaborator)[0].join(", ") }}
        </h4>
        <h5 class="text-base font-medium text-gray-dark">
          {{ Object.keys(collaborator)[0] }}
        </h5>
        <!-- find a way to reduce, like by grouping according to task -->
        <!-- a outreach description of the task exist, possible to add it -->
      </li>
    </ul>

    <ul v-if="props.partners[0]" class="pl-6 flex flex-col gap-3">
      <UnderlineTitle title="Partenaires" :fontSize="3" />
      <li
        v-for="partner in props.partners"
        :key="partner.name"
        class="pl-2 flex flex-col gap-1"
      >
        <h5 class="text-base font-medium text-gray-dark">
          — {{ partner.taskName }}
        </h5>
        <h4
          class="text-lg font-medium after:block after:w-20 after:h-1 after:bg-black"
        >
          {{ partner.name }}
        </h4>
      </li>
    </ul>
  </div>
</template>

<style scoped></style>
