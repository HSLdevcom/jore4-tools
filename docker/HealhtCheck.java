import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse.BodyHandlers;

static void main(String[] args) throws IOException, InterruptedException {
    final var client = HttpClient.newHttpClient();
    final var request = HttpRequest.newBuilder()
            .uri(URI.create("http://localhost:8080/actuator/health"))
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
