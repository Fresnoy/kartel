import axios from "axios";

import {
    input,
    result,
    artworks,
    artists,
    search,
    hiddenInput,
    searchArtworks,
    searchArtists
} from "@/composables/search"

import paginatedArtworkFixture from "~/fixtures/paginatedArtwork.json"
import paginatedArtistFixture from "~/fixtures/paginatedArtist.json"

// instance doesn't work with mock ?! axios.create results undefined
// https://runthatline.com/how-to-mock-axios-with-vitest/
vi.mock("axios");

describe("Test search composable behaviour", () => {
    beforeEach(() => {
        axios.post.mockReset();
        input.value = "";
        artworks.value = [];
        artists.value = [];

      });

    it("search function clear artist and artwork array if input search is too short", () => {
        artworks.value = ["coucou"];
        artists.value = ["coucou"];

        input.value = "c"
        search(input.value);

        expect(artworks.value).toStrictEqual([]);
        expect(artists.value).toStrictEqual([]);
    })

    it("search function keep artwork and artist data if input is long enough", () => {
        artworks.value = ["coucou"];
        artists.value = ["coucou"];

        input.value = "coucou"
        search(input.value);

        expect(artworks.value).toStrictEqual(["coucou"]);
        expect(artists.value).toStrictEqual(["coucou"]);
    })

    it("hidden input return false value if hidden input'input is correct", () => {
        input.value = "coucou"

        expect(hiddenInput(input.value)).toBe(false);
    })

    it("hiden input return true if input value is empty", () => {
        input.value = "";

        expect(hiddenInput(input.value)).toBe(true);
    })

    it("hiden input return true if input value is null", () => {
        input.value = null;

        expect(hiddenInput(input.value)).toBe(true);
    })

    it("hiden input return true if input value is not an alhpanumeric character", () => {
        input.value = "!@#$%^&*()";

        expect(hiddenInput(input.value)).toBe(true);
    })

    it("check artist's query wich match", async () => {
        axios.post.mockResolvedValue(paginatedArtistFixture);

        searchArtists("sele");

        expect(artists.value.artist).toEqual(paginatedArtistFixture.data.data.artistsPagination.edges.node);
    })

    it("check artist's query wich don't match", async () => {
        axios.post.mockResolvedValue(paginatedArtistFixture);

        searchArtists("solo");

        expect(artists.value).toEqual([]);
    })

    it("check artist's query error", async () => {
        const errorMessage = 'Network Error';
        axios.post.mockResolvedValue(new Error(errorMessage));

        const query = await searchArtists("sele");
        expect(query).toBeUndefined();
    })

    it("check artwork's query which match", async () => {
        axios.post.mockResolvedValue(paginatedArtworkFixture);

        searchArtworks("mémo");

        expect(artworks.value.artwork).toEqual(paginatedArtworkFixture.data.data.artworksPagination.edges.node);
    })

    it("check artwork's query which doesn't match", async () => {
        axios.post.mockResolvedValue(paginatedArtworkFixture);

        searchArtworks("mama");

        expect(artworks.value).toEqual([]);
    })

    it("check artwork's query which match", async () => {
        const errorMessage = 'Network Error';
        axios.post.mockResolvedValue(new Error(errorMessage))

        const query = await searchArtworks("mémo");
        expect(query).toBeUndefined();
    })
})
