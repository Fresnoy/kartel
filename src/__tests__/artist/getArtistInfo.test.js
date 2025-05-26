import axios from "axios";

import {
  setup,
  artist,
  user,
  artworks,
  student,
  candidature,
  initValues,
  getArtist,
  getArtworks,
  getStudent,
  getUser,
  getCandidature,
} from "@/composables/artist/getArtistInfo";

/**

  fixtures

**/
import artistFixture from "~/fixtures/artist.json";
import userFixture from "~/fixtures/user.json";
import noStudentArtistFixture from "~/fixtures/noStudentArtist.json";
import applicationFixture from "~/fixtures/studentApplication.json";

vi.mock("axios");

describe("test the composable getArtistInfo", () => {
  beforeEach(() => {
    axios.post.mockReset();
    artist.value = {};
    artworks.value = [];
    student.value = {};
    user.value = {};
    candidature.value = {};
  });

  it("Init values", () => {
    initValues();

    expect(artist.value).toEqual({});
    expect(artworks.value).toEqual([]);
    expect(student.value).toEqual({});
    expect(user.value).toEqual({});
    expect(candidature.value).toEqual({});
  });

  it("Get artist", async () => {
    axios.post
      .mockResolvedValue(
        // default mock but not the first
        {
          data: {
            default: true,
          },
        })
      // success once and fail once
      .mockResolvedValueOnce(artistFixture)
      .mockRejectedValueOnce({ mockMessage: "Error" });

    /**
     * Test with success
     */
    await getArtist(artistFixture.id);

    expect(axios.post).toHaveBeenCalledTimes(1);
    expect(artist.value).toEqual(artistFixture.data.data.artist);

    /**
     * Test with Fail
     */
    await getArtist(artistFixture.id);

    expect(axios.post).toHaveBeenCalledTimes(2);
    expect(artist.value).toEqual({});
  });

  it("Get user", async () => {
    axios.post
      .mockResolvedValue(// default mock but not the first
        {
          data: {
            default: true,
          },
        })
      // success once and fail once
      .mockResolvedValueOnce(userFixture)
      .mockRejectedValueOnce({ mockMessage: "Error" });

    await getUser(userFixture.id);

    expect(axios.post).toHaveBeenCalledTimes(1);
    expect(user.value).toEqual(userFixture.data.data.user);
  });

  it("Get user error", async () => {
    const errorMessage = 'Network Error';
    axios.post.mockResolvedValue(new Error(errorMessage))

    getUser(errorMessage);

    expect(user.value).toEqual({});
  });

  it("Get artworks", async () => {
    axios.post
      .mockResolvedValue(
        // default mock but not the first
        {
          data: {
            default: true,
          },
        }
      )
      // success once and fail once
      // the response of the request is always a array even if it's just one artwork
      .mockResolvedValueOnce(artistFixture)
      .mockRejectedValueOnce({ mockMessage: "Error" });

      await getArtworks(artistFixture);

    expect(axios.post).toHaveBeenCalledTimes(1);
    expect(artworks.value).toEqual(artistFixture.data.data.artist.artworks);
  });

  it("Get artworks error", async () => {
    const errorMessage = 'Network Error';
    axios.post.mockResolvedValue(new Error(errorMessage))

    await getArtworks(errorMessage);
    expect(artworks.value).toEqual([]);
  });

  it("Get student succeed", async () => {
    axios.post
      .mockResolvedValue(
        // default mock but not the first
        {
          data: {
            default: true,
          },
        }
      )
      // success once and fail once
      // the response of the request is always a array even if it's just one artwork
      .mockResolvedValueOnce(artistFixture)
      .mockRejectedValueOnce({ mockMessage: "Error" })

      await getStudent(artistFixture.id);

      expect(axios.post).toHaveBeenCalledTimes(1);
      expect(student.value).toEqual(artistFixture.data.data.artist.student);
  });

  it("Get no student because the artist is not a student", async () => {
    axios.post
      .mockResolvedValue(
        // default mock but not the first
        {
          data: {
            default: true,
          },
        }
      )
      // success once and fail once
      // the response of the request is always a array even if it's just one artwork
      .mockResolvedValueOnce(noStudentArtistFixture)
      .mockRejectedValueOnce({ mockMessage: "Error" })

      await getStudent(noStudentArtistFixture.id);

      expect(axios.post).toHaveBeenCalledTimes(1);
      expect(student.value).toEqual([]);
  });

  it("Get student error", async () => {
    const errorMessage = 'Network Error';
    axios.post.mockResolvedValue(new Error(errorMessage))

    await getStudent(errorMessage);

    expect(axios.post).toHaveBeenCalledTimes(1);
    expect(student.value).toEqual({});
  });

  //rework this code, its weird that it work like that
  it("Get candidature with success", async () => {
    axios.post
      .mockResolvedValue(
        // default mock but not the first
        {
          data: {
            default: true,
          },
        }
      )
      // success once and fail once
      // the response of the request is always a array even if it's just one artwork
      .mockResolvedValueOnce(applicationFixture)
      .mockRejectedValueOnce({ mockMessage: "Error" });

    await getCandidature(applicationFixture.id);

    expect(axios.post).toHaveBeenCalledTimes(1);
    expect(candidature.value).toEqual(applicationFixture.data.data.studentApplication);
  });

  it("Get candidature with error", async () => {
    const errorMessage = 'Network Error';
    axios.post.mockResolvedValue(new Error(errorMessage))

    await getCandidature(errorMessage);
    expect(candidature.value).toEqual({});
  });

  //rework this test
  it("Check setup without authentication", async () => {
    axios.post
      .mockResolvedValue(
        // default mock but not the first
        {
          data: {
            default: true,
          },
        }
      )
      // success once and fail once
      // the response of the request is always a array even if it's just one artwork
      .mockResolvedValueOnce(artistFixture)
      .mockResolvedValueOnce(userFixture)

    await setup(artistFixture.id, false);
    console.log("artist", artist.value);
    console.log("user", user.value);

    expect(axios.post).toHaveBeenCalledTimes(2);
    expect(artist.value).toEqual(artistFixture.data.data.artist);
    expect(user.value).toEqual(userFixture.data.data.user);
  });
});
