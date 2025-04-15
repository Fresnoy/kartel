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
          query {
            promotion(id: ${promoId}) {
              students {
                id
                nickname
                firstName
                lastName
                photo
                nationality
                cursus
                number
                graduate
                diplomaMention
                artist {
                  id
                }
                promotion {
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

        return await this.getStudentsInfos(data.data.promotion.students);
      } catch (err) {
        console.error(err);
      }
    }

    /**
     * Asynchronously retrieves user data for a list of students.
     * @async
     *
     * @param {Array} students - An array of student objects.
     * @returns {Promise<Array>} - A Promise that resolves to an array of student objects with retrieved user data.
     */
    async getStudentsInfos(students) {
      const users = students.map(async (student) => {
        student.userData = student;
        student.artistData = await this.getArtist(student.user.id);

        return student;
      });
      return await Promise.all(users);
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
            query {
              user(id: ${parent}) {
                artist {
                  id
                  nickname
                  photo
                  bioShortFr
                  bioShortEn
                  bioFr
                  bioEn
                  twitterAccount
                  facebookProfile
                  members {
                    id
                  }
                  websites {
                    id
                  }
                  artworks {
                    id
                  }
                  teacher {
                    id
                  }
                  visitingStudent {
                    id
                  }
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
        query{
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
   * Sorts an array of student objects by last name.
   *
   * @param {Array} students - The array of student objects to sort.
   * @param {string} order - The order in which to sort the students. Can be "ascending" or "descending".
   * @returns {Array} - The sorted array of student objects.
   */
  function sortStudents(students, order) {
    // for Promotion Marguerite Duras sort invert V and Y for Yoo and Villafagne ?!
    if (order === "descending") {
      const sort = students.sort((a, b) => {
        // Sort with lower or upper case for avoid bad sorting because not the same Unicode
        let aName = a.artistData.nickname ? a.artistData.nickname : a.userData.lastName;
        let bName = b.artistData.nickname ? b.artistData.nickname : b.userData.lastName;
        return aName < bName ? 1 : -1;
      });
      return (students = sort);
    } else {
      const sort = students.sort((a, b) => {
        let aName = a.artistData.nickname ? a.artistData.nickname : a.userData.lastName;
        let bName = b.artistData.nickname ? b.artistData.nickname : b.userData.lastName;
        return aName > bName ? 1 : -1
      });
      return (students = sort);
    }
    
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
