// General helper functions
def validate_path_param(
    param_option, 
    param, 
    type="file", 
    mandatory=true) {
        valid_types=["file", "directory"]
        if (!valid_types.any { it == type }) {
                log.error("Invalid type '${type}'. Possibilities are ${valid_types}.")
                return 1
        }
        param_name = (param_option - "--").replaceAll("_", " ")
        if (param) {
            def file_param = file(param)
            if (!file_param.exists()) {
                log.error("The given ${param_name} '${param}' does not exist.")
                return 1
            } else if (
                (type == "file" && !file_param.isFile())
                ||
                (type == "directory" && !file_param.isDirectory())
            ) {
                log.error("The given ${param_name} '${param}' is not a ${type}.")
                return 1
            }
        } else if (mandatory) {
            log.error("No ${param_name} specified. Please specify one using the ${param_option} option.")
            return 1
        }
        return 0
    }

def validate_choice_param(param_option, param, choices) {
    param_name = (param_option - "--").replaceAll("_", " ")
    if (!choices.contains(param)) {
        log.error("Please specify the ${param_name} using the ${param_option} option. Possibilities are ${choices}.")
        return 1
    }
    return 0
}

def validate_number_param(param_option, param) {
    param_name = (param_option - "--").replaceAll("_", " ")
    if (param != null) /* Explicit comparison with null, because 0 is an acceptable value */ {
        if (!(param instanceof Number)) {
            log.error("The ${param_name} specified with the ${param_option} option must be a valid number")
            return 1
        }
    } else {
        log.error("Please specify the ${param_name} using the ${param_option} option")
        return 1
    }
    return 0
}

/*
Functions Unique to mags_maker 
*/
def validate_contiglen(param_option, param, binnername, minlength) {

    int value = param as int 
    if (value < minlength) {
        log.error("${binnername} require a minimum contig length of at least ${minlength}, but you provided a length of '${param}' to option '${param_option}'")
        return 1
    }
    return 0
}

def validate_parameters() {
    int errors = 0
    println "start parameter validation"
    int minlength_metabat = 1500 // a software requirement
    errors += validate_contiglen("--metabat_min_contig", params.metabat_min_contig, "Metabat1 and Metabat2", minlength_metabat)
    int minlength_concoct = 500 // not a software requirement, but the minimum it's been tested with; cf. https://academic.oup.com/bioinformatics/article/32/4/605/1744462
    errors += validate_contiglen("--concoct_min_contig", params.concoct_min_contig, "Concoct", minlength_concoct)
    int minlength_maxbin2 = 500 // not a software requirement, but the minimum it's been tested with; cf. https://academic.oup.com/bioinformatics/article/32/4/605/1744462
    errors += validate_contiglen("--maxbin2_min_contig", params.maxbin2_min_contig, "Maxbin2", minlength_maxbin2)

    if (errors > 0) {
        log.error(String.format("%d errors detected", errors))
        exit 1
    }
    println "end parameter validation"
}