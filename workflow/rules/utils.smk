rule wget:
    output:
        outfile="",
    params:
        url="",
    log:
        "logs/wget.log",
    shell:
        """
        wget {params.url} -O {output} 2> {log}
        """
