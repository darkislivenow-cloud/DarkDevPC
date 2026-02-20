
Typical usage flow for you

- You are on your own machine in the folder C:\Users\darkd\Documents\Runner .
- You create a list of targets you want to test (their IPs/hostnames).
- You either:
  - Run once for a single target:
    ```
    python job.py -u https://192.
    168.1.200
    ```
  - Or create targets.txt and run:
    ```
    python job.py -f targets.txt
    ```
- Optionally add:
  - -o output.txt to save results.
  - --only-valid to only show entries that look like valid sessions.










Single URL with -u / --url

Example:

Bash



Run
python job.py -u https://192.168.1.200
or if you don’t include the scheme:

Bash



Run
python job.py -u 192.168.1.200
The script will then normalize it to something like https://192.168.1.200.

Multiple URLs from a file with -f / --file

You create a text file yourself, e.g. targets.txt in the same folder as job.py, with one URL or hostname per line, for example:

text



https://192.168.1.200https://gateway.company.local10.0.0.5
Then you run:

Bash



Run
python job.py -f targets.txt
Inside job.py, the -f option tells it “read this file line by line and treat each line as a target URL”.

3. How does the script use those URLs?

For each target (either from -u or from the file):

It passes the string to normalize_url, which:

Adds https:// if there’s no http:// or https://.
Strips any path, keeping only scheme://host[:port].
Then it appends the fixed path it wants to hit, like:

Python



f"{full_url}/oauth/redacted"
It sends an HTTP request to that path to try to dump memory, and then tries to extract and test session tokens from the response bytes.

So the target URL you provide is just the base of the server (IP or hostname, optionally with scheme/port). The script takes care of the exact vulnerable endpoint path.

4. Typical usage flow for you

You are on your own machine in the folder C:\Users\darkd\Documents\Runner.
You create a list of targets you want to test (their IPs/hostnames).
You either:
Run once for a single target:
Bash



Run
python job.py -u https://192.168.1.200
Or create targets.txt and run:
Bash



Run
python job.py -f targets.txt
Optionally add:
-o output.txt to save results.
--only-valid to only show entries that look like valid sessions.