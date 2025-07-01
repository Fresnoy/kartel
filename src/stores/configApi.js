import { defineStore } from "pinia";
import { ref } from "vue";

import axios from "axios";

import config from "@/config";

export const useConfigApi = defineStore("configApi", () => {
  let promotions = ref([]);
  let selectedPromo = ref([]);

  let promotion = ref({
    map: new Map(),
    id: "",
    data: "",
    students: [],
    load: false,
  });

  class Students {
    constructor(promoId) {
      this.promoId = promoId;

      promotion.value.id = promoId;
      promotion.value.students = [];

      this.getPromotion(this.promoId);
    }

    /**
     * retrieves a promotion with the specified ID and assigns it to the global promotion object.
     *
     * @async
     * @param {string} promoId - The identifier of the promotion to retrieve.
     * @returns {Promise<void>} A promise that resolves when the promotion has been retrieved and assigned.
     */
    async getPromotion(promoId) {
      let studentsPromotion = promotions.value.find(
        (promo) => (promo.id) == promoId
      );

      promotion.value.data = studentsPromotion;
    }

    /**
     * Fetches and caches the list of students for a given promotion ID.
     * @async
     *
     * @returns {Array} The list of students for the promotion.
     */
    async getStudents() {
      if (promotion.value.map.has(this.promoId)) {
        return (promotion.value.students = promotion.value.map.get(
          this.promoId
        ));
      }

      promotion.value.load = true;

      promotion.value.map.set(
        this.promoId,
        await this.fetchStudents(this.promoId)
      );

      if (this.promoId === promotion.value.id) {
        promotion.value.students = promotion.value.map.get(this.promoId);
      }
      promotion.value.load = false;
    }

    /**
     * Fetches students from a school API based on their promotion ID and returns users data.
     * @async
     *
     * @param {string} promoId - The ID of the promotion to fetch students from.
     * @returns {Promise} A promise that resolves to the users data.
     * @throws {Error} If an error occurs while fetching the students.
     */
    async fetchStudents(promoId) {
      try {
        let response = await axios.post( `${config.v3_graph}`, {
         query:`
          query GetStudents {
            promotion(id: ${promoId}) {
              students {
                photo
                displayName
                artist {
                  id
                }
                user {
                 id
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
        let data = response.data;

        sortStudents(data.data.promotion.students, "")

        return data.data.promotion.students;
      } catch (err) {
        console.error(err);
      }
    }

    /**
     * Async function to retrieve user data from a given student object.
     * @async
     *
     * @param {Object} student - The student object containing the user data.
     * @returns {Promise<Object>} - The user data retrieved from the API.
     * @throws {Error} - An error occurred while retrieving the user data.
     */
    async getUser(student) {
      try {
        const response = await axios.get(student.user);
        const userData = response.data;

        return await userData;
      } catch (err) {
        console.error(err);
      }
    }

    /**
     * Async function to retrieve user data from a given student object.
     * @async
     *
     * @param {Object} parent - The parent object containing the artist data.
     * @returns {Promise<Object>} - The artist data retrieved from the API.
     * @throws {Error} - An error occurred while retrieving the artist data.
     */
    async getArtist(parent) {
      try {
        const response = await axios.post(`${config.v3_graph}`, {
          query: `
            query GetArtist {
              user(id: ${parent}) {
                artist {
                  id
                }
              }
            }
          `, 
        }, {
          headers: {
            'Content-Type': 'application/json'
          }
        });
        const artistData = response.data.data.user.artist;

        return await artistData;
      } catch (err) {
        console.error(err);
      }
    }
  }

  /**
   * Retrieves a list of promotions from the school API, sorts them by descending starting year,
   * and assigns the sorted list to the `promotions` value.
   *
   */
  async function getPromotions() {
    let response = await axios.post(`${config.v3_graph}`, {
      query: `
        query GetPromotions {
          promotions {
            id
            name
            endingYear
            startingYear
            picture
          }
        }
      `,
    }, {
      headers: {
        'Content-Type': 'application/json'
      }
    });

    let data = response.data.data.promotions;

    //sort in order to have latest promotion first
    //Sort by descending promotions
    const descendingStartingYear = data.sort(
      (a, b) => b.startingYear - a.startingYear
    );

    promotions.value = descendingStartingYear;
  }

  /**
   * Retrieve the list of students for the specified promo ID.
   *
   * @param {string} promoId - The ID of the promo to retrieve the students for.
   * @returns {Promise<Student[]>} - A Promise that resolves with an array of Student objects.
   */

  function getSelectedPromo(promoId) {
    new Students(promoId).getStudents();
  }

  /**
   * Format students to return lastnames in upper case in order to sort them in sortStudent().
   *
   * @param {string} fullName - The full name of a student, can be alphabeticalOrder or displayName
   * @returns {string} - Lastname, or full name if there is no lastname, in uppercase.
   */
  function formatSortingNames(fullName) {
    if (fullName.split(" ").length >= 2) { 
      let isolatedName = fullName.split(" ").slice(1).join();
      return isolatedName.toUpperCase();
    }
    return fullName.toUpperCase();
  }

  /**
   * Sorts an array of student objects by last name.
   *
   * @param {Array} students - The array of student objects to sort.
   * @param {string} order - The order in which to sort the students. Can be "ascending" or "descending".
   * @returns {Array} - The sorted array of student objects.
   */
  function sortStudents(students, order) {
      students.sort((a, b) => {
        let aName = a.alphabeticalOrder? formatSortingNames(a.alphabeticalOrder): formatSortingNames(a.displayName);
        let bName = b.alphabeticalOrder? formatSortingNames(b.alphabeticalOrder): formatSortingNames(b.displayName);


        if (order === "descending") {
          return aName < bName ? 1 : -1;
        }
        return aName > bName ? 1 : -1;
      });    
  }

  return {
    getPromotions,
    getSelectedPromo,
    promotion,
    promotions,
    selectedPromo,
    sortStudents,
  };
});
