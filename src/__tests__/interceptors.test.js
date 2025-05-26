import axios from "axios";
import { load, requests, requestsProgress, requestsStatus, atRequest, atResponse} from "@/composables/interceptors";

describe("Test loading behaviour", () => {
    beforeEach(() => {
        load.value.status = false;
        load.value.progress = 0;
        requests.value = [];
        vi.clearAllMocks();
        vi.useFakeTimers();
    });

    afterEach(() => {
        vi.useRealTimers();
    });

    it("load initial values", () => {
        expect(load.value.status).toBe(false);
        expect(load.value.progress).toBe(0);
    })

    it("load with updated values", () => {
        load.value.status = true;
        load.value.progress = 50;

        expect(load.value.status).toBe(true);
        expect(load.value.progress).toBe(50);
    })

    it('interceptor successful request', async () => {
        const mockConfig = { url: "http://127.0.0.1:8000/graphql"};

        axios.interceptors.request.handlers[0].fulfilled(mockConfig);
    
        expect(load.value.status).toBe(true);
    });

    it('interceptor bad request', async () => {
        const errorMessage = new Error('Request failed');
        const mockConfig = { url: "http://127.0.0.1:8000/graphql"};
        errorMessage.config = mockConfig;

        const interceptor = axios.interceptors.request.handlers[0];
        await expect(interceptor.rejected(errorMessage)).rejects.toThrow('Request failed')
    });

    it("Test some functions", () => {
        // get the config of the request
        atRequest({ url: "http://127.0.0.1:8000/graphql"});
        
        load.value.status = !requestsStatus();
        expect(load.value.status).toBe(true);

        //test bar progress
        requestsProgress();
        expect(load.value.progress).toBe(0);

        //load response
        atResponse({ config: { url: "http://127.0.0.1:8000/graphql"}});

        // Test bar progress again
        requestsProgress();

        // test request states
        expect(load.value.progress).toBe(100);
        expect(requests.value[0].completed).toBe(true);

        // update load value status
        load.value.status = !requestsStatus();
        expect(load.value.status).toBe(false);
        vi.advanceTimersByTime(3000);
        expect(requests.value).toStrictEqual([]);
    });
});
