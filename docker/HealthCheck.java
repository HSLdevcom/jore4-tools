// Source: https://www.naiyerasif.com/post/2021/03/01/java-based-health-check-for-docker/
// Original code license: CC BY-SA 4.0 | https://www.naiyerasif.com/about/#frequently-asked-questions

/**
 * How to compile:
 * javac HealthCheck.java
 * jar --create --file HealthCheck.jar --main-class HealthCheck HealthCheck.class
 * rm HealthCheck.class
 *
 * Remember to compile and/or target for the proper Java version.
 * Currently Tiamat requires 21, while others could support 25.
 * So 21 is used as the baseline support level.
 */

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse.BodyHandlers;

public class HealthCheck {
    public static void main(String[] args) throws IOException, InterruptedException {
        final var port = args.length > 0 ? args[0] : "8080";

        final var client = HttpClient.newHttpClient();
        final var request = HttpRequest.newBuilder()
                .uri(URI.create("http://localhost:" + port + "/actuator/health"))
                .header("accept", "application/json")
                .build();

        final var response = client.send(request, BodyHandlers.ofString());
        final var body = response.body();

        System.out.print("Status: " + response.statusCode());
        System.out.print(" | body: " + body);
        System.out.println();

        if (response.statusCode() != 200 || !body.contains("UP")) {
            System.err.println("Service is not UP!");
            System.exit(1);
        } else {
            System.exit(0);
        }
    }
}
